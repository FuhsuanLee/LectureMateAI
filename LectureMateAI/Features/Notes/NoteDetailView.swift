//
//  NoteDetailView.swift
//  LectureMateAI
//
//  Created by Sherry Lee on 2026/6/3.
//

import SwiftUI
import SwiftData

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
                        FlashcardReviewView(
                            flashcards: note.flashcards,
                            deckTitle: note.title
                        )
                    } label: {
                        ReviewToolRow(
                            title: "Flashcards",
                            subtitle: flashcardsSubtitle,
                            countText: "\(note.flashcards.count)",
                            systemImage: "rectangle.on.rectangle",
                            tint: .orange
                        )
                    }

                    NavigationLink {
                        QuizView(questions: note.quizQuestions)
                    } label: {
                        ReviewToolRow(
                            title: "Quiz",
                            subtitle: quizSubtitle,
                            countText: "\(note.quizQuestions.count)",
                            systemImage: "questionmark.circle",
                            tint: .blue
                        )
                    }
                }
            }
        }
        .navigationTitle(note.title)
    }

    private var flashcardsSubtitle: String {
        if note.flashcards.isEmpty {
            return "No flashcards generated yet"
        }

        return "Tap to review important terms one by one"
    }

    private var quizSubtitle: String {
        if note.quizQuestions.isEmpty {
            return "No quiz questions generated yet"
        }

        return "Test your understanding with generated questions"
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

private struct ReviewToolRow: View {
    let title: String
    let subtitle: String
    let countText: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(tint.opacity(0.14))
                    .frame(width: 44, height: 44)

                Image(systemName: systemImage)
                    .font(.headline)
                    .foregroundStyle(tint)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(countText)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.thinMaterial)
                .clipShape(Capsule())
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        NoteDetailView(note: previewLectureNote)
    }
    .modelContainer(for: [
        Course.self,
        LectureNote.self,
        Flashcard.self,
        QuizQuestion.self
    ], inMemory: true)
}

private var previewLectureNote: LectureNote {
    let note = LectureNote(
        title: "Chapter 4 - Sorting",
        markdown: """
        # Chapter 4 - Sorting

        ## 一 本堂課重點摘要
        - 比較 Bubble Sort、Insertion Sort、Merge Sort
        - 說明時間複雜度與空間複雜度

        ## 二 章節式筆記
        排序演算法可以分成穩定排序與不穩定排序，也可以依照是否採用分治法來分類。

        ## 三 專有名詞整理
        | 名詞 | 解釋 | 課堂中的例子 |
        | --- | --- | --- |
        | Time Complexity | 演算法執行時間成長趨勢 | O(n log n) |
        """
    )

    note.flashcards = [
        Flashcard(term: "Stable Sort", definitionText: "排序後相同元素的相對順序保持不變", example: "Merge Sort")
    ]

    note.quizQuestions = [
        QuizQuestion(
            question: "哪一個排序法平均時間複雜度是 O(n log n)？",
            options: ["Bubble Sort", "Selection Sort", "Merge Sort", "Insertion Sort"],
            correctIndex: 2,
            explanation: "Merge Sort 採用分治法，平均與最壞情況都能維持 O(n log n)。"
        )
    ]

    return note
}
