//
//  NoteDetailView.swift
//  LectureMateAI
//
//  Created by Sherry Lee on 2026/6/3.
//

import SwiftUI

struct NoteDetailView: View {
    let note: LectureNote

    var body: some View {
        List {
            Section("AI Markdown Note") {
                MarkdownText(markdown: note.markdown)
                    .padding(.vertical, 8)
            }

            if !note.flashcards.isEmpty || !note.quizQuestions.isEmpty {
                Section("Review Tools") {
                    NavigationLink {
                        FlashcardReviewView(flashcards: note.flashcards)
                    } label: {
                        Label("Flashcards", systemImage: "rectangle.on.rectangle")
                    }

                    NavigationLink {
                        QuizView(questions: note.quizQuestions)
                    } label: {
                        Label("Quiz", systemImage: "questionmark.circle")
                    }
                }
            }
        }
        .navigationTitle(note.title)
    }
}

struct MarkdownText: View {
    let markdown: String

    var body: some View {
        if let attributed = try? AttributedString(markdown: markdown) {
            Text(attributed)
        } else {
            Text(markdown)
        }
    }
}
