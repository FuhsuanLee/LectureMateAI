//
//  GenerateNoteView.swift
//  LectureMateAI
//
//  Created by Sherry Lee on 2026/6/3.
//

import SwiftUI
import SwiftData
import TipKit

struct GenerateNoteView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let course: Course
    @AppStorage("aiBackendMode") private var aiBackendMode = AIBackendMode.cloud
    @StateObject private var modelManager = ModelManager.shared

    @State private var lectureTitle = ""
    @State private var transcript = ""
    @State private var slideText = ""
    @State private var isGenerating = false

    private var aiService: AIService {
        switch aiBackendMode {
        case .cloud:
            return OpenAIService()
        case .local:
            return LocalAIService()
        }
    }

    private let tip = GenerateNoteTip()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                TipView(tip)

                TextField("Lecture title", text: $lectureTitle)
                    .textFieldStyle(.roundedBorder)

                VStack(alignment: .leading) {
                    Text("Lecture Transcript")
                        .font(.headline)

                    TextEditor(text: $transcript)
                        .frame(height: 180)
                        .padding(8)
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                VStack(alignment: .leading) {
                    Text("Slide Content")
                        .font(.headline)

                    TextEditor(text: $slideText)
                        .frame(height: 140)
                        .padding(8)
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    generateNote()
                } label: {
                    VStack(spacing: 4) {
                        HStack {
                            if isGenerating {
                                ProgressView()
                            }

                            Text(isGenerating ? "Generating..." : "Generate AI Note")
                                .fontWeight(.semibold)
                        }
                        
                        if aiBackendMode == .local {
                            switch modelManager.gemmaState {
                            case .notDownloaded:
                                Text("Download Gemma 4 in Settings first")
                                    .font(.caption2)
                                    .opacity(0.8)
                            case .downloading(let progress):
                                Text("Downloading Gemma 4... \(Int(progress * 100))%")
                                    .font(.caption2)
                                    .opacity(0.8)
                            case .error(let message):
                                Text("Model Error: \(message)")
                                    .font(.caption2)
                                    .opacity(0.8)
                                    .foregroundStyle(.red)
                            case .downloaded:
                                EmptyView()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(lectureTitle.isEmpty || transcript.isEmpty || isGenerating || (aiBackendMode == .local && modelManager.gemmaState != .downloaded))
            }
            .padding()
        }
        .navigationTitle("AI Generate")
    }

    private func generateNote() {
        isGenerating = true

        Task {
            do {
                let markdown = try await aiService.generateMarkdownNote(
                    lectureTitle: lectureTitle,
                    transcript: transcript,
                    pdfText: slideText
                )

                await MainActor.run {
                    let note = LectureNote(
                        title: lectureTitle,
                        markdown: markdown
                    )

                    note.flashcards = AIOutputParser.parseFlashcards(from: markdown)

                    modelContext.insert(note)
                    course.notes.append(note)

                    try? modelContext.save()

                    isGenerating = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isGenerating = false
                }
            }
        }
    }
}
