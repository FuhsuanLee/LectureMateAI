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

private enum GenerationStage: Equatable {
    case idle
    case preparing
    case extractingPDF
    case transcribingAudio
    case generatingMarkdown
    case savingNote
    case completed

    var title: String {
        switch self {
        case .idle:
            return "Ready to import"
        case .preparing:
            return "Preparing lecture files"
        case .extractingPDF:
            return "Extracting PDF text"
        case .transcribingAudio:
            return "Transcribing audio"
        case .generatingMarkdown:
            return "Generating markdown note"
        case .savingNote:
            return "Saving lecture note"
        case .completed:
            return "Lecture note saved"
        }
    }

    var detail: String {
        switch self {
        case .idle:
            return "Upload one lecture audio or video file and one PDF. The transcript and PDF text will be processed automatically when you generate the note."
        case .preparing:
            return "Checking the selected files and getting everything ready for AI processing."
        case .extractingPDF:
            return "Reading text from your PDF slides with PDFKit."
        case .transcribingAudio:
            return "Sending the lecture audio to OpenAI and creating a transcript."
        case .generatingMarkdown:
            return "Combining the transcript and slide text into a structured markdown note."
        case .savingNote:
            return "Saving the generated note into the current course."
        case .completed:
            return "Your note has been saved. Returning to the course page..."
        }
    }

    var systemImage: String {
        switch self {
        case .idle:
            return "square.and.arrow.down.on.square"
        case .preparing, .extractingPDF, .transcribingAudio, .generatingMarkdown, .savingNote:
            return "sparkles"
        case .completed:
            return "checkmark.circle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .completed:
            return .green
        case .idle:
            return .secondary
        case .preparing, .extractingPDF, .transcribingAudio, .generatingMarkdown, .savingNote:
            return .blue
        }
    }

    var progressValue: Double? {
        switch self {
        case .idle:
            return nil
        case .preparing:
            return 0.08
        case .extractingPDF:
            return 0.2
        case .transcribingAudio:
            return 0.5
        case .generatingMarkdown:
            return 0.8
        case .savingNote:
            return 0.95
        case .completed:
            return 1.0
        }
    }

    var activeStepIndex: Int? {
        switch self {
        case .idle, .completed:
            return nil
        case .preparing, .extractingPDF:
            return 0
        case .transcribingAudio:
            return 1
        case .generatingMarkdown:
            return 2
        case .savingNote:
            return 3
        }
    }

    var completedStepCount: Int {
        switch self {
        case .idle, .preparing, .extractingPDF:
            return 0
        case .transcribingAudio:
            return 1
        case .generatingMarkdown:
            return 2
        case .savingNote:
            return 3
        case .completed:
            return 4
        }
    }

    var isProcessing: Bool {
        switch self {
        case .preparing, .extractingPDF, .transcribingAudio, .generatingMarkdown, .savingNote:
            return true
        case .idle, .completed:
            return false
        }
    }
}

private enum ProcessingStep: Int, CaseIterable, Identifiable {
    case extractPDF
    case transcribeAudio
    case generateMarkdown
    case saveNote

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .extractPDF:
            return "Extract PDF text"
        case .transcribeAudio:
            return "Transcribe audio"
        case .generateMarkdown:
            return "Generate markdown"
        case .saveNote:
            return "Save to course"
        }
    }

    var subtitle: String {
        switch self {
        case .extractPDF:
            return "Read slide content with PDFKit"
        case .transcribeAudio:
            return "Create a transcript with OpenAI"
        case .generateMarkdown:
            return "Combine transcript and slide content"
        case .saveNote:
            return "Store the lecture note in SwiftData"
        }
    }
}

private enum ProcessingStepState {
    case pending
    case active
    case complete

    var systemImage: String {
        switch self {
        case .pending:
            return "circle"
        case .active:
            return "hourglass.circle.fill"
        case .complete:
            return "checkmark.circle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .pending:
            return .secondary
        case .active:
            return .blue
        case .complete:
            return .green
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
    @State private var generationStage: GenerationStage = .idle
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
        AppBackground {
            AppScrollPage(bottomPadding: 44) {
                VStack(alignment: .leading, spacing: 22) {
                    lectureTitleSection
                    uploadSectionCard(
                        title: "Upload Lecture Audio or Video",
                        subtitle: "We'll transcribe your lecture automatically when you generate the note.",
                        token: AppPalette.noteTokens[0],
                        buttonTitle: "Upload MP3 / MP4 / M4A",
                        emptyStateText: "No audio or video file selected yet",
                        filename: selectedAudioFilename,
                        metadata: audioMetadataText,
                        onUpload: { presentImporter(for: .audio) },
                        onClear: clearAudioSelection
                    )

                    uploadSectionCard(
                        title: "Upload PDF Slides",
                        subtitle: "PDFKit will extract slide text so the AI can build better notes.",
                        token: AppPalette.noteTokens[1],
                        buttonTitle: "Upload PDF",
                        emptyStateText: "No PDF file selected yet",
                        filename: selectedPDFFilename,
                        metadata: pdfMetadataText,
                        onUpload: { presentImporter(for: .pdf) },
                        onClear: clearPDFSelection
                    )

                    if isBusy || generationStage == .completed || canGenerateNote {
                        generationStatusCard()
                    }

                    Button {
                        generateMarkdownNote()
                    } label: {
                        HStack(spacing: 12) {
                            if isGeneratingNote {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "sparkles")
                            }

                            VStack(spacing: 4) {
                                Text(generateButtonTitle)

                                if !isGeneratingNote {
                                    Text("AI will create a structured markdown note from your lecture")
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.85))
                                }
                            }
                        }
                    }
                    .buttonStyle(AppPrimaryButtonStyle())
                    .disabled(!canGenerateNote)
                    .opacity(canGenerateNote ? 1.0 : 0.76)

                    if !errorMessage.isEmpty {
                        errorCard()
                    }

                    HStack(spacing: 10) {
                        Image(systemName: "lock")
                            .foregroundStyle(AppTheme.secondaryText)

                        Text("Your files stay on-device except for OpenAI processing needed to transcribe and generate notes.")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture {
                    dismissKeyboard()
                }
            }
        }
        .navigationTitle("Import Lecture")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        .animation(.easeInOut(duration: 0.2), value: isGeneratingNote)
        .animation(.easeInOut(duration: 0.2), value: generationStage)
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

    private var lectureTitleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Lecture Title")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.secondaryText)

            HStack {
                TextField("Machine Learning Basics - Lecture 12", text: $lectureTitle)
                    .font(.system(size: 21, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.ink)
                    .focused($isLectureTitleFocused)

                Text("\(trimmedLectureTitle.count)/100")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .appInputField()
            .appCard(cornerRadius: 28)
        }
    }

    private var generateButtonTitle: String {
        if isGeneratingNote {
            return generationStage.title
        }

        return "Generate Markdown Note"
    }

    private func presentImporter(for type: ImportType) {
        dismissKeyboard()
        errorMessage = ""
        if !isGeneratingNote {
            generationStage = .idle
        }
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

    private var audioMetadataText: String {
        selectedAudioURL.flatMap(readableFileSize(for:)) ?? "Ready for automatic transcription"
    }

    private var pdfMetadataText: String {
        guard let selectedPDFURL else {
            return "Text will be extracted automatically"
        }

        let sizeText = readableFileSize(for: selectedPDFURL) ?? "PDF"
        let pageCount = PDFDocument(url: selectedPDFURL)?.pageCount ?? 0

        if pageCount > 0 {
            return "\(sizeText) • \(pageCount) pages"
        }

        return sizeText
    }

    private func clearAudioSelection() {
        selectedAudioURL = nil
        selectedAudioFilename = ""
        transcript = ""
        if !isGeneratingNote {
            generationStage = .idle
        }
    }

    private func clearPDFSelection() {
        selectedPDFURL = nil
        selectedPDFFilename = ""
        pdfText = ""
        if !isGeneratingNote {
            generationStage = .idle
        }
    }

    private func readableFileSize(for url: URL) -> String? {
        let values = try? url.resourceValues(forKeys: [.fileSizeKey])
        guard let fileSize = values?.fileSize else { return nil }

        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(fileSize))
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

        dismissKeyboard()
        isGeneratingNote = true
        generationStage = .preparing
        errorMessage = ""

        let title = trimmedLectureTitle

        Task {
            do {
                await MainActor.run {
                    generationStage = .extractingPDF
                }

                let extractedPDFText = try extractPDFText(from: selectedPDFURL)

                await MainActor.run {
                    pdfText = extractedPDFText
                    generationStage = .transcribingAudio
                }

                let transcribedText = try await openAIService.transcribeAudio(fileURL: selectedAudioURL)

                await MainActor.run {
                    transcript = transcribedText
                    generationStage = .generatingMarkdown
                }

                let markdown = try await openAIService.generateMarkdownNote(
                    lectureTitle: title,
                    transcript: transcribedText,
                    pdfText: extractedPDFText
                )

                await MainActor.run {
                    generationStage = .savingNote
                    saveNote(title: title, markdown: markdown)
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to generate note: \(userFacingMessage(for: error))"
                    generationStage = .idle
                    isGeneratingNote = false
                }
            }
        }
    }

    @MainActor
    private func saveNote(title: String, markdown: String) {
        let note = LectureNote(title: title, markdown: markdown)
        note.flashcards = AIOutputParser.parseFlashcards(from: markdown)

        modelContext.insert(note)
        course.notes.append(note)

        do {
            try modelContext.save()
            generationStage = .completed
            isGeneratingNote = false

            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                dismiss()
            }
        } catch {
            errorMessage = "Failed to save note: \(userFacingMessage(for: error))"
            generationStage = .idle
            isGeneratingNote = false
        }
    }

    private func importChecklistCard() -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Import Checklist", systemImage: "checklist")
                .font(.headline)

            checklistRow(
                title: "Lecture title",
                detail: trimmedLectureTitle.isEmpty ? "Enter a title for this lecture" : trimmedLectureTitle,
                isComplete: !trimmedLectureTitle.isEmpty
            )

            checklistRow(
                title: "Audio or video",
                detail: selectedAudioFilename.isEmpty ? "Upload one MP3, MP4, or M4A file" : selectedAudioFilename,
                isComplete: selectedAudioURL != nil
            )

            checklistRow(
                title: "PDF slides",
                detail: selectedPDFFilename.isEmpty ? "Upload the lecture PDF slides" : selectedPDFFilename,
                isComplete: selectedPDFURL != nil
            )
        }
        .padding(16)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func generationStatusCard() -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(generationStage.tint.opacity(0.14))
                        .frame(width: 54, height: 54)

                    Image(systemName: generationStage.systemImage)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(generationStage.tint)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(statusCardTitle)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.ink)

                    Text(statusCardDetail)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }

            if let progressValue = generationStage.progressValue {
                ProgressView(value: progressValue)
                    .tint(generationStage.tint)
            }

            if generationStage.isProcessing || generationStage == .completed {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(ProcessingStep.allCases) { step in
                        processingStepRow(step: step, state: processingState(for: step))
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(20)
        .background(backgroundColor(for: generationStage))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.8), lineWidth: 1)
        )
        .shadow(color: AppTheme.softShadow, radius: 18, x: 0, y: 10)
    }

    private var statusCardTitle: String {
        if generationStage == .idle {
            return "Ready to generate"
        }

        return generationStage.title
    }

    private var statusCardDetail: String {
        if generationStage == .idle {
            return "When you tap Generate, the app will extract PDF text, transcribe your lecture audio with OpenAI, and save the markdown note automatically."
        }

        return generationStage.detail
    }

    private func errorCard() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Something went wrong", systemImage: "exclamationmark.triangle.fill")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.red)

            Text(errorMessage)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.primary)

            if let suggestion = recoverySuggestion {
                Text(suggestion)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
        .padding(20)
        .background(AppTheme.red.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var recoverySuggestion: String? {
        let lowercasedMessage = errorMessage.lowercased()

        if lowercasedMessage.contains("api key") {
            return "Check OpenAIConfig.swift and confirm your local testing API key is still filled in."
        }

        if lowercasedMessage.contains("pdf") {
            return "Try a text-based PDF instead of a scanned image PDF, then import it again."
        }

        if lowercasedMessage.contains("too large") || lowercasedMessage.contains("25 mb") {
            return "Try a shorter lecture clip or a smaller audio export if the source media is very long."
        }

        if lowercasedMessage.contains("unsupported") || lowercasedMessage.contains("corrupted") {
            return "Try another MP3 or M4A file to confirm the source media is readable."
        }

        return nil
    }

    private func uploadSectionCard(
        title: String,
        subtitle: String,
        token: AppVisualToken,
        buttonTitle: String,
        emptyStateText: String,
        filename: String,
        metadata: String,
        onUpload: @escaping () -> Void,
        onClear: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                AppIconTile(token: token, size: 58)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.ink)

                    Text(subtitle)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }

            Button(action: onUpload) {
                VStack(spacing: 10) {
                    Image(systemName: "icloud.and.arrow.up")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(token.gradient)

                    Text(buttonTitle)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(token.tint)

                    Text("Tap to choose your file")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.secondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(token.softTint.opacity(0.35))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(token.tint.opacity(0.35), style: StrokeStyle(lineWidth: 1.5, dash: [8, 6]))
                )
            }
            .buttonStyle(.plain)
            .disabled(isBusy)

            if !filename.isEmpty {
                selectedFileRow(
                    title: title,
                    filename: filename,
                    metadata: metadata,
                    token: token,
                    onClear: onClear
                )
            } else {
                hintText(emptyStateText)
            }
        }
        .padding(22)
        .appCard(cornerRadius: 30)
    }

    @ViewBuilder
    private func selectedFileRow(
        title: String,
        filename: String,
        metadata: String,
        token: AppVisualToken,
        onClear: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(token.softTint)
                    .frame(width: 52, height: 52)

                Image(systemName: token.icon)
                    .foregroundStyle(token.gradient)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(filename)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(2)

                Text(metadata)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.secondaryText)
            }

            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.green)

                Button(action: onClear) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(AppTheme.secondaryText)
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(Color.white.opacity(0.82)))
                }
                .buttonStyle(.plain)
                .disabled(isBusy)
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.66))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func hintText(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .foregroundStyle(AppTheme.secondaryText)
    }

    private func checklistRow(title: String, detail: String, isComplete: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: isComplete ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isComplete ? .green : .secondary)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))

                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()
        }
    }

    private func processingStepRow(step: ProcessingStep, state: ProcessingStepState) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: state.systemImage)
                .foregroundStyle(state.tint)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 3) {
                Text(step.title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)

                Text(step.subtitle)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.secondaryText)
            }

            Spacer()
        }
    }

    private func processingState(for step: ProcessingStep) -> ProcessingStepState {
        if generationStage.completedStepCount > step.rawValue {
            return .complete
        }

        if generationStage.activeStepIndex == step.rawValue {
            return .active
        }

        return .pending
    }

    private func backgroundColor(for stage: GenerationStage) -> Color {
        switch stage {
        case .completed:
            return .green.opacity(0.10)
        case .idle:
            return AppTheme.blue.opacity(0.08)
        case .preparing, .extractingPDF, .transcribingAudio, .generatingMarkdown, .savingNote:
            return AppTheme.blue.opacity(0.10)
        }
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

#Preview {
    NavigationStack {
        FileImportGenerateView(course: previewImportCourse)
    }
    .modelContainer(for: [
        Course.self,
        LectureNote.self,
        Flashcard.self,
        QuizQuestion.self
    ], inMemory: true)
}

private var previewImportCourse: Course {
    Course(title: "Data Structures")
}
