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
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                TextField("Lecture title", text: $lectureTitle)
                    .textFieldStyle(.roundedBorder)
                    .focused($isLectureTitleFocused)

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

                importChecklistCard()

                if isBusy || canGenerateNote || generationStage == .completed {
                    generationStatusCard()
                }

                Button {
                    generateMarkdownNote()
                } label: {
                    HStack {
                        if isGeneratingNote {
                            ProgressView()
                        }

                        Text(generateButtonTitle)
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
                    errorCard()
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
                Image(systemName: generationStage.systemImage)
                    .font(.title3)
                    .foregroundStyle(generationStage.tint)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 6) {
                    Text(statusCardTitle)
                        .font(.headline)

                    Text(statusCardDetail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
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
        .padding(16)
        .background(backgroundColor(for: generationStage))
        .clipShape(RoundedRectangle(cornerRadius: 16))
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
                .font(.headline)
                .foregroundStyle(.red)

            Text(errorMessage)
                .font(.subheadline)
                .foregroundStyle(.primary)

            if let suggestion = recoverySuggestion {
                Text(suggestion)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(.red.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
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
                    .font(.subheadline.weight(.semibold))

                Text(step.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
            return .blue.opacity(0.08)
        case .preparing, .extractingPDF, .transcribingAudio, .generatingMarkdown, .savingNote:
            return .blue.opacity(0.10)
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
