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
        AppBackground {
            AppScrollPage(bottomPadding: 44) {
                VStack(alignment: .leading, spacing: 22) {
                    headerCard
                    markdownSection

                    if !note.flashcards.isEmpty || !note.quizQuestions.isEmpty {
                        reviewSection
                    }
                }
            }
        }
        .navigationTitle(note.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerCard: some View {
        let token = AppPalette.noteToken(for: note.title)

        return VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 16) {
                AppIconTile(token: token, size: 72)

                VStack(alignment: .leading, spacing: 10) {
                    Text(note.title)
                        .font(.system(size: 29, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.ink)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)

                    Text(note.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.secondaryText)

                    HStack(spacing: 8) {
                        AppPill(text: "Markdown Note", color: AppTheme.blue)

                        if !note.flashcards.isEmpty {
                            AppPill(text: "\(note.flashcards.count) Flashcards", color: AppTheme.purple)
                        }

                        if !note.quizQuestions.isEmpty {
                            AppPill(text: "\(note.quizQuestions.count) Quiz", color: AppTheme.orange)
                        }
                    }
                }
            }
        }
        .padding(20)
        .appCard(cornerRadius: 32)
    }

    private var markdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("AI Markdown Note", systemImage: "doc.text")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)

            MarkdownText(markdown: note.markdown)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
                .padding(20)
                .appCard(cornerRadius: 30)
        }
    }

    private var reviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Review Tools", systemImage: "sparkles")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)

            if !note.flashcards.isEmpty {
                NavigationLink {
                    FlashcardReviewView(
                        flashcards: note.flashcards,
                        deckTitle: note.title
                    )
                } label: {
                    ReviewToolCard(
                        title: "Flashcards",
                        subtitle: flashcardsSubtitle,
                        countText: "\(note.flashcards.count)",
                        token: AppPalette.noteTokens[4]
                    )
                }
                .buttonStyle(.plain)
            }

            if !note.quizQuestions.isEmpty {
                NavigationLink {
                    QuizView(questions: note.quizQuestions)
                } label: {
                    ReviewToolCard(
                        title: "Quiz",
                        subtitle: quizSubtitle,
                        countText: "\(note.quizQuestions.count)",
                        token: AppPalette.noteTokens[3]
                    )
                }
                .buttonStyle(.plain)
            }
        }
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
                .lineSpacing(6)
        } else {
            Text(markdown)
                .lineSpacing(6)
        }
    }
}

private struct ReviewToolCard: View {
    let title: String
    let subtitle: String
    let countText: String
    let token: AppVisualToken

    var body: some View {
        HStack(spacing: 16) {
            AppIconTile(token: token, size: 64)

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)

                Text(subtitle)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineLimit(2)
            }

            Spacer()

            VStack(spacing: 10) {
                Text(countText)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(token.tint)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(token.softTint)
                    .clipShape(Capsule())

                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
        .padding(18)
        .appCard()
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
