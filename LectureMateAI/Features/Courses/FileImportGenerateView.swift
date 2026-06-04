//
//  FileImportGenerateView.swift
//  LectureMateAI
//
//  Created by Sherry Lee on 2026/6/3.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import PDFKit

private enum ImportType {
    case audio
    case pdf

    var allowedContentTypes: [UTType] {
        switch self {
        case .audio:
            var types: [UTType] = [.audio, .movie]

            if let mp3 = UTType(filenameExtension: "mp3") {
                types.append(mp3)
            }

            if let mp4 = UTType(filenameExtension: "mp4") {
                types.append(mp4)
            }

            if let m4a = UTType(filenameExtension: "m4a") {
                types.append(m4a)
            }

            return types

        case .pdf:
            return [.pdf]
        }
    }
}

private enum FileImportError: LocalizedError {
    case unsupportedFile
    case unreadablePDF
    case emptyPDFText

    var errorDescription: String? {
        switch self {
        case .unsupportedFile:
            return "The selected file could not be accessed"
        case .unreadablePDF:
            return "The selected PDF could not be opened"
        case .emptyPDFText:
            return "The PDF was imported, but no extractable text was found"
        }
    }
}

struct FileImportGenerateView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let course: Course
    private let openAIService = OpenAIService()

    @State private var lectureTitle = ""

    @State private var selectedAudioURL: URL?
    @State private var selectedAudioFilename = ""
    @State private var selectedPDFURL: URL?
    @State private var selectedPDFFilename = ""

    @State private var transcript = ""
    @State private var pdfText = ""

    @State private var showFileImporter = false
    @State private var importType: ImportType?
    @FocusState private var isLectureTitleFocused: Bool

    @State private var isGeneratingNote = false
    @State private var currentProgressMessage = ""
    @State private var errorMessage = ""

    private var trimmedLectureTitle: String {
        lectureTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isBusy: Bool {
        isGeneratingNote
    }

    private var canGenerateNote: Bool {
        !trimmedLectureTitle.isEmpty &&
        selectedAudioURL != nil &&
        selectedPDFURL != nil &&
        !isBusy
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                TextField("Lecture title", text: $lectureTitle)
                    .textFieldStyle(.roundedBorder)
                    .focused($isLectureTitleFocused)

                if isBusy {
                    VStack(alignment: .leading, spacing: 8) {
                        Label(currentProgressMessage, systemImage: "hourglass")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                        Text("Upload Lecture Audio or Video")
                            .font(.headline)

                    Button {
                        presentImporter(for: .audio)
                    } label: {
                        Label("Upload MP3 / MP4 / M4A", systemImage: "waveform")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.blue.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(isBusy)

                    if !selectedAudioFilename.isEmpty {
                        selectedFileRow(
                            title: "Selected audio",
                            filename: selectedAudioFilename,
                            systemImage: "checkmark.circle.fill"
                        )
                    } else {
                        hintText("No audio file selected yet")
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Upload PDF Slides")
                        .font(.headline)

                    Button {
                        presentImporter(for: .pdf)
                    } label: {
                        Label("Upload PDF", systemImage: "doc.richtext")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.green.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(isBusy)

                    if !selectedPDFFilename.isEmpty {
                        selectedFileRow(
                            title: "Selected PDF",
                            filename: selectedPDFFilename,
                            systemImage: "checkmark.circle.fill"
                        )
                    } else {
                        hintText("No PDF file selected yet")
                    }
                }

                Button {
                    generateMarkdownNote()
                } label: {
                    HStack {
                        if isGeneratingNote {
                            ProgressView()
                        }

                        Text(isGeneratingNote ? "Generating Markdown Note..." : "Generate Markdown Note")
                            .fontWeight(.semibold)
                    }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(!canGenerateNote)

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .padding()
            .onTapGesture {
                dismissKeyboard()
            }
        }
        .navigationTitle("Import Lecture")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: importType?.allowedContentTypes ?? [.data],
            allowsMultipleSelection: false
        ) { result in
            switch importType {
            case .audio:
                handleAudioImport(result)

            case .pdf:
                handlePDFImport(result)

            case .none:
                break
            }

            importType = nil
        }
    }

    private func dismissKeyboard() {
        isLectureTitleFocused = false
    }

    private func presentImporter(for type: ImportType) {
        errorMessage = ""
        importType = type

        DispatchQueue.main.async {
            showFileImporter = true
        }
    }

    private func handleAudioImport(_ result: Result<[URL], Error>) {
        do {
            guard let sourceURL = try result.get().first else { return }

            let localURL = try copyImportedFileToTemporaryDirectory(from: sourceURL)
            selectedAudioURL = localURL
            selectedAudioFilename = sourceURL.lastPathComponent
            transcript = ""

            errorMessage = ""
        } catch {
            errorMessage = "Failed to import audio file: \(userFacingMessage(for: error))"
        }
    }

    private func handlePDFImport(_ result: Result<[URL], Error>) {
        do {
            guard let sourceURL = try result.get().first else { return }

            let localURL = try copyImportedFileToTemporaryDirectory(from: sourceURL)

            selectedPDFURL = localURL
            selectedPDFFilename = sourceURL.lastPathComponent
            pdfText = ""
            errorMessage = ""
        } catch {
            errorMessage = "Failed to import PDF file: \(userFacingMessage(for: error))"
        }
    }

    private func copyImportedFileToTemporaryDirectory(from sourceURL: URL) throws -> URL {
        let fileManager = FileManager.default
        let tempDirectory = fileManager.temporaryDirectory
            .appendingPathComponent("LectureMateAIImports", isDirectory: true)

        try fileManager.createDirectory(at: tempDirectory, withIntermediateDirectories: true)

        let canAccess = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if canAccess {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        let destinationURL = tempDirectory.appendingPathComponent(
            "\(UUID().uuidString)-\(sourceURL.lastPathComponent)"
        )

        do {
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
            return destinationURL
        } catch {
            throw FileImportError.unsupportedFile
        }
    }

    private func extractPDFText(from url: URL) throws -> String {
        guard let document = PDFDocument(url: url) else {
            throw FileImportError.unreadablePDF
        }

        var result = ""

        for index in 0..<document.pageCount {
            guard let page = document.page(at: index) else { continue }
            result += "\n\n--- Page \(index + 1) ---\n"
            result += page.string ?? ""
        }

        let extractedText = result.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !extractedText.isEmpty else {
            throw FileImportError.emptyPDFText
        }

        return extractedText
    }

    private func generateMarkdownNote() {
        guard !trimmedLectureTitle.isEmpty else {
            errorMessage = "Please enter a lecture title"
            return
        }

        guard let selectedAudioURL else {
            errorMessage = "Please choose an audio or video file first"
            return
        }

        guard let selectedPDFURL else {
            errorMessage = "Please choose a PDF file first"
            return
        }

        isGeneratingNote = true
        currentProgressMessage = "Preparing lecture files..."
        errorMessage = ""

        let title = trimmedLectureTitle

        Task {
            do {
                await MainActor.run {
                    currentProgressMessage = "Extracting PDF text..."
                }

                let extractedPDFText = try extractPDFText(from: selectedPDFURL)

                await MainActor.run {
                    pdfText = extractedPDFText
                    currentProgressMessage = "Transcribing audio with OpenAI..."
                }

                let transcribedText = try await openAIService.transcribeAudio(fileURL: selectedAudioURL)

                await MainActor.run {
                    transcript = transcribedText
                    currentProgressMessage = "Generating markdown note with OpenAI..."
                }

                let markdown = try await openAIService.generateMarkdownNote(
                    lectureTitle: title,
                    transcript: transcribedText,
                    pdfText: extractedPDFText
                )

                await MainActor.run {
                    saveNote(title: title, markdown: markdown)
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to generate note: \(userFacingMessage(for: error))"
                    isGeneratingNote = false
                }
            }
        }
    }

    @MainActor
    private func saveNote(title: String, markdown: String) {
        let note = LectureNote(title: title, markdown: markdown)

        modelContext.insert(note)
        course.notes.append(note)

        do {
            try modelContext.save()
            currentProgressMessage = ""
            isGeneratingNote = false
            dismiss()
        } catch {
            errorMessage = "Failed to save note: \(userFacingMessage(for: error))"
            currentProgressMessage = ""
            isGeneratingNote = false
        }
    }

    @ViewBuilder
    private func selectedFileRow(title: String, filename: String, systemImage: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .foregroundStyle(.green)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(filename)
                    .font(.subheadline)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(12)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func hintText(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private func userFacingMessage(for error: Error) -> String {
        if let localizedError = error as? LocalizedError,
           let description = localizedError.errorDescription,
           !description.isEmpty {
            return description
        }

        return error.localizedDescription
    }
}
