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

    @State private var lectureTitle = ""
    @State private var transcript = ""
    @State private var slideText = ""
    @State private var isGenerating = false

    private let tip = GenerateNoteTip()

    var body: some View {
        Form {
            Section {
                TipView(tip)
            }

            Section("Lecture Title") {
                TextField("Lecture title", text: $lectureTitle)
            }

            Section("Lecture Transcript") {
                TextEditor(text: $transcript)
                    .frame(minHeight: 160)
            }

            Section("Slide Content") {
                TextEditor(text: $slideText)
                    .frame(minHeight: 120)
            }

            Section {
                Button {
                    generateNote()
                } label: {
                    HStack(spacing: 8) {
                        if isGenerating {
                            ProgressView()
                        }

                        Text(isGenerating ? "Generating…" : "Generate AI Note")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(lectureTitle.isEmpty || transcript.isEmpty || isGenerating)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
        }
        .navigationTitle("AI Generate")
    }

    private func generateNote() {
        isGenerating = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            let result = MockAIService.generateNote(
                lectureTitle: lectureTitle,
                transcript: transcript,
                slideText: slideText
            )

            let note = LectureNote(
                title: lectureTitle,
                markdown: result.markdown
            )

            note.flashcards = result.flashcards
            note.quizQuestions = result.quizQuestions

            modelContext.insert(note)
            course.notes.append(note)

            try? modelContext.save()

            isGenerating = false
            dismiss()
        }
    }
}
