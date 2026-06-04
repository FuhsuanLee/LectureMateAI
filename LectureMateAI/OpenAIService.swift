//
//  OpenAIService.swift
//  LectureMateAI
//
//  Created by Sherry Lee on 2026/6/3.
//

import AVFoundation
import Foundation

struct OpenAIService {
    private let session: URLSession
    private let maxTranscriptionFileSizeBytes = 25 * 1024 * 1024
    private let preferredChunkFileSizeBytes = 18 * 1024 * 1024
    private let minimumChunkDurationSeconds = 30.0
    private let maximumChunkDurationSeconds = 5 * 60.0

    init(session: URLSession = .shared) {
        self.session = session
    }

    func transcribeAudio(fileURL: URL) async throws -> String {
        guard !OpenAIConfig.apiKey.isEmpty else {
            throw OpenAIError.missingAPIKey
        }

        let preparedAudio = try await prepareAudioFileForTranscription(from: fileURL)
        var cleanupURLs = preparedAudio.cleanupURLs

        defer {
            cleanupTemporaryFiles(at: cleanupURLs)
        }

        let chunkURLs = try await chunkAudioFileIfNeeded(preparedAudio.audioURL)
        cleanupURLs.append(contentsOf: chunkURLs.filter { $0 != preparedAudio.audioURL })

        var transcriptSegments: [String] = []

        for (index, chunkURL) in chunkURLs.enumerated() {
            let prompt = transcriptionPrompt(
                forChunkAt: index,
                totalChunks: chunkURLs.count,
                previousTranscriptSegments: transcriptSegments
            )

            let segmentTranscript = try await transcribeSingleAudioFile(
                fileURL: chunkURL,
                prompt: prompt
            )

            transcriptSegments.append(segmentTranscript)
        }

        let transcript = transcriptSegments
            .joined(separator: "\n\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !transcript.isEmpty else {
            throw OpenAIError.emptyResponse
        }

        return transcript
    }

    func generateMarkdownNote(
        lectureTitle: String,
        transcript: String,
        pdfText: String
    ) async throws -> String {
        guard !OpenAIConfig.apiKey.isEmpty else {
            throw OpenAIError.missingAPIKey
        }

        let trimmedLectureTitle = lectureTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedTranscript = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPDFText = pdfText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedLectureTitle.isEmpty else {
            throw OpenAIError.invalidInput("Lecture title cannot be empty")
        }

        guard !trimmedTranscript.isEmpty else {
            throw OpenAIError.invalidInput("Transcript cannot be empty")
        }

        guard !trimmedPDFText.isEmpty else {
            throw OpenAIError.invalidInput("PDF text cannot be empty")
        }

        let endpoint = URL(string: "https://api.openai.com/v1/responses")!

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(OpenAIConfig.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let instructions = """
        你是一位專業的課堂筆記整理助理。請只輸出 \(OpenAIConfig.language) Markdown，不要加入前言、結語、程式碼區塊或額外說明。
        """

        let prompt = """
        請根據以下資料產生一份適合學生複習的課堂筆記。

        課程標題：\(trimmedLectureTitle)

        請嚴格使用以下 Markdown 結構：

        # \(trimmedLectureTitle)

        ## 一 本堂課重點摘要
        條列整理本堂課最重要的內容

        ## 二 章節式筆記
        依照 PDF 投影片內容與 transcript 整理成清楚章節

        ## 三 專有名詞整理
        使用 Markdown table，欄位必須包含：名詞 | 解釋 | 課堂中的例子

        ## 四 考試可能重點
        整理可能會考的觀念、比較題、應用題或計算題方向

        ## 五 Flashcards
        使用 Q / A 格式列出專有名詞複習卡

        ## 六 Quiz
        產生 5 題選擇題。每題都要包含：
        題目
        A.
        B.
        C.
        D.
        正確答案
        解析

        如果 transcript 與 PDF 內容有不一致，請優先整合成學生容易理解的版本，並保留重要名詞。

        以下是 lecture transcript：
        \(trimmedTranscript)

        以下是 PDF 投影片文字：
        \(trimmedPDFText)
        """

        let body = ResponsesRequest(
            model: OpenAIConfig.noteModel,
            instructions: instructions,
            temperature: OpenAIConfig.temperature,
            input: prompt
        )

        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)

        try validateResponse(response: response, data: data)

        let decoded = try JSONDecoder().decode(ResponsesResponse.self, from: data)

        if let text = decoded.outputText {
            return text
        }

        throw OpenAIError.emptyResponse
    }

    private func prepareAudioFileForTranscription(from fileURL: URL) async throws -> PreparedAudioFile {
        let fileExtension = fileURL.pathExtension.lowercased()

        switch fileExtension {
        case "mp4", "mov":
            let extractedAudioURL = try await extractAudioTrack(from: fileURL)
            return PreparedAudioFile(audioURL: extractedAudioURL, cleanupURLs: [extractedAudioURL])
        default:
            return PreparedAudioFile(audioURL: fileURL, cleanupURLs: [])
        }
    }

    private func chunkAudioFileIfNeeded(_ fileURL: URL) async throws -> [URL] {
        let fileSize = try fileSizeForURL(fileURL)
        guard fileSize > 0 else {
            throw OpenAIError.invalidInput("The selected audio file is empty")
        }

        let asset = AVURLAsset(url: fileURL)
        let duration = try await asset.load(.duration)
        let durationSeconds = CMTimeGetSeconds(duration)

        guard durationSeconds.isFinite, durationSeconds > 0 else {
            throw OpenAIError.invalidInput("Unable to determine the audio duration for chunking")
        }

        guard fileSize > maxTranscriptionFileSizeBytes || durationSeconds > maximumChunkDurationSeconds else {
            return [fileURL]
        }

        var chunkURLs: [URL] = []
        var currentStartSeconds = 0.0

        while currentStartSeconds < durationSeconds {
            let remainingSeconds = durationSeconds - currentStartSeconds
            let targetChunkDuration = estimatedChunkDuration(
                fileSizeBytes: fileSize,
                durationSeconds: durationSeconds
            )
            let currentChunkDuration = min(targetChunkDuration, remainingSeconds)

            let exportedChunkURLs = try await exportChunkRecursively(
                asset: asset,
                startSeconds: currentStartSeconds,
                durationSeconds: currentChunkDuration
            )

            chunkURLs.append(contentsOf: exportedChunkURLs)
            currentStartSeconds += currentChunkDuration
        }

        return chunkURLs
    }

    private func estimatedChunkDuration(fileSizeBytes: Int, durationSeconds: Double) -> Double {
        let bytesPerSecond = Double(fileSizeBytes) / durationSeconds

        guard bytesPerSecond.isFinite, bytesPerSecond > 0 else {
            return maximumChunkDurationSeconds
        }

        let duration = Double(preferredChunkFileSizeBytes) / bytesPerSecond
        let boundedDuration = min(duration, maximumChunkDurationSeconds)
        return max(minimumChunkDurationSeconds, boundedDuration)
    }

    private func extractAudioTrack(from fileURL: URL) async throws -> URL {
        let asset = AVURLAsset(url: fileURL)
        let audioTracks = try await asset.loadTracks(withMediaType: .audio)

        guard !audioTracks.isEmpty else {
            throw OpenAIError.noAudioTrack
        }

        guard let exportSession = AVAssetExportSession(
            asset: asset,
            presetName: AVAssetExportPresetAppleM4A
        ) else {
            throw OpenAIError.audioExtractionFailed("Unable to create audio export session")
        }

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")

        exportSession.outputURL = outputURL
        exportSession.outputFileType = .m4a
        exportSession.shouldOptimizeForNetworkUse = true

        do {
            try await exportSession.export(to: outputURL, as: .m4a)
            return outputURL
        } catch {
            throw OpenAIError.audioExtractionFailed(error.localizedDescription)
        }
    }

    private func exportChunkRecursively(
        asset: AVURLAsset,
        startSeconds: Double,
        durationSeconds: Double
    ) async throws -> [URL] {
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")

        let timeRange = CMTimeRange(
            start: CMTime(seconds: startSeconds, preferredTimescale: 600),
            duration: CMTime(seconds: durationSeconds, preferredTimescale: 600)
        )

        try await exportAudioChunk(asset: asset, timeRange: timeRange, outputURL: outputURL)

        let chunkFileSize = try fileSizeForURL(outputURL)

        guard chunkFileSize > 0 else {
            throw OpenAIError.invalidInput("A generated audio chunk was empty")
        }

        if chunkFileSize <= maxTranscriptionFileSizeBytes {
            return [outputURL]
        }

        try? FileManager.default.removeItem(at: outputURL)

        guard durationSeconds > minimumChunkDurationSeconds else {
            throw OpenAIError.audioFileTooLarge(maxSizeMB: 25)
        }

        let halfDuration = durationSeconds / 2

        let firstHalf = try await exportChunkRecursively(
            asset: asset,
            startSeconds: startSeconds,
            durationSeconds: halfDuration
        )

        let secondHalf = try await exportChunkRecursively(
            asset: asset,
            startSeconds: startSeconds + halfDuration,
            durationSeconds: durationSeconds - halfDuration
        )

        return firstHalf + secondHalf
    }

    private func exportAudioChunk(
        asset: AVURLAsset,
        timeRange: CMTimeRange,
        outputURL: URL
    ) async throws {
        guard let exportSession = AVAssetExportSession(
            asset: asset,
            presetName: AVAssetExportPresetAppleM4A
        ) else {
            throw OpenAIError.audioExtractionFailed("Unable to create audio chunk export session")
        }

        exportSession.timeRange = timeRange
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .m4a
        exportSession.shouldOptimizeForNetworkUse = true

        do {
            try await exportSession.export(to: outputURL, as: .m4a)
        } catch {
            throw OpenAIError.audioExtractionFailed(error.localizedDescription)
        }
    }

    private func transcribeSingleAudioFile(fileURL: URL, prompt: String) async throws -> String {
        let endpoint = URL(string: "https://api.openai.com/v1/audio/transcriptions")!

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(OpenAIConfig.apiKey)", forHTTPHeaderField: "Authorization")

        let boundary = UUID().uuidString
        request.setValue(
            "multipart/form-data; boundary=\(boundary)",
            forHTTPHeaderField: "Content-Type"
        )

        let fileData = try Data(contentsOf: fileURL, options: .mappedIfSafe)
        let fileName = fileURL.lastPathComponent
        let mimeType = mimeTypeForFile(url: fileURL)

        var body = Data()

        body.appendMultipartField(
            name: "model",
            value: OpenAIConfig.transcriptionModel,
            boundary: boundary
        )

        body.appendMultipartField(
            name: "language",
            value: OpenAIConfig.transcriptionLanguageCode,
            boundary: boundary
        )

        body.appendMultipartField(
            name: "response_format",
            value: "json",
            boundary: boundary
        )

        body.appendMultipartField(
            name: "prompt",
            value: prompt,
            boundary: boundary
        )

        body.appendMultipartFile(
            name: "file",
            filename: fileName,
            mimeType: mimeType,
            fileData: fileData,
            boundary: boundary
        )

        body.appendString("--\(boundary)--\r\n")
        request.httpBody = body

        let (data, response) = try await session.data(for: request)

        try validateResponse(response: response, data: data)

        let decoded = try JSONDecoder().decode(TranscriptionResponse.self, from: data)
        let transcript = decoded.text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !transcript.isEmpty else {
            throw OpenAIError.emptyResponse
        }

        return transcript
    }

    private func transcriptionPrompt(
        forChunkAt index: Int,
        totalChunks: Int,
        previousTranscriptSegments: [String]
    ) -> String {
        let basePrompt = "Traditional Chinese lecture audio. Preserve technical terms and English keywords."

        guard totalChunks > 1 else {
            return basePrompt
        }

        let hasPriorTranscript = !previousTranscriptSegments.isEmpty
        let continuityHint = hasPriorTranscript
            ? "Continue naturally from the prior chunk."
            : "Start of the lecture."

        return "\(basePrompt) Chunk \(index + 1) of \(totalChunks). \(continuityHint)"
    }

    private func fileSizeForURL(_ fileURL: URL) throws -> Int {
        let values = try fileURL.resourceValues(forKeys: [.fileSizeKey])
        return values.fileSize ?? 0
    }

    private func cleanupTemporaryFiles(at urls: [URL]) {
        let uniqueURLs = Array(Set(urls))

        for url in uniqueURLs {
            try? FileManager.default.removeItem(at: url)
        }
    }

    private func validateResponse(response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }

        guard 200..<300 ~= httpResponse.statusCode else {
            if let decodedError = try? JSONDecoder().decode(OpenAIAPIErrorResponse.self, from: data) {
                throw OpenAIError.apiError(decodedError.error.message)
            }

            let message = String(data: data, encoding: .utf8) ?? "Unknown API error"
            throw OpenAIError.apiError(message)
        }
    }

    private func mimeTypeForFile(url: URL) -> String {
        let ext = url.pathExtension.lowercased()

        switch ext {
        case "mp3":
            return "audio/mpeg"
        case "m4a":
            return "audio/mp4"
        case "mp4":
            return "video/mp4"
        case "wav":
            return "audio/wav"
        default:
            return "application/octet-stream"
        }
    }
}

private struct PreparedAudioFile {
    let audioURL: URL
    let cleanupURLs: [URL]
}

enum OpenAIError: LocalizedError {
    case missingAPIKey
    case emptyResponse
    case invalidInput(String)
    case invalidResponse
    case audioFileTooLarge(maxSizeMB: Int)
    case noAudioTrack
    case audioExtractionFailed(String)
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "OpenAI API key is missing"
        case .emptyResponse:
            return "OpenAI returned an empty response"
        case .invalidInput(let message):
            return message
        case .invalidResponse:
            return "The app received an invalid response from OpenAI"
        case .audioFileTooLarge(let maxSizeMB):
            return "The audio file is too large for transcription. Please keep it under \(maxSizeMB) MB."
        case .noAudioTrack:
            return "The selected video does not contain an audio track."
        case .audioExtractionFailed(let message):
            return "Failed to extract audio from the selected video: \(message)"
        case .apiError(let message):
            if message.localizedCaseInsensitiveContains("total number of tokens in instructions + audio is too large") {
                return "This audio segment is still too long for the transcription model. The app now uses smaller time-based chunks, so please try the transcription again."
            }

            if message.localizedCaseInsensitiveContains("corrupted or unsupported") {
                return "OpenAI could not read this media file. Please try an MP3 or M4A file, or use an MP4 that contains a valid audio track."
            }

            return message
        }
    }
}
