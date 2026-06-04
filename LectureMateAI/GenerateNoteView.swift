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
                    HStack {
                        if isGenerating {
                            ProgressView()
                        }

                        Text(isGenerating ? "Generating..." : "Generate AI Note")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(lectureTitle.isEmpty || transcript.isEmpty || isGenerating)
            }
            .padding()
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
