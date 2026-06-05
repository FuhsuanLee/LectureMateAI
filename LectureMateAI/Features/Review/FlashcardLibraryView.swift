//
//  FlashcardLibraryView.swift
//  LectureMateAI
//
//  Created by Sherry Lee on 2026/6/5.
//

import SwiftUI
import SwiftData

struct FlashcardLibraryView: View {
    @Query(sort: \Course.createdAt, order: .reverse) private var courses: [Course]

    private var coursesWithFlashcards: [Course] {
        courses.filter { course in
            course.notes.contains { !$0.flashcards.isEmpty }
        }
    }

    private var allFlashcards: [Flashcard] {
        coursesWithFlashcards
            .flatMap(\.notes)
            .flatMap(\.flashcards)
    }

    private var totalDecks: Int {
        coursesWithFlashcards
            .flatMap(\.notes)
            .filter { !$0.flashcards.isEmpty }
            .count
    }

    var body: some View {
        NavigationStack {
            AppBackground {
                AppScrollPage(topPadding: 22) {
                    VStack(alignment: .leading, spacing: 22) {
                        headerSection
                        summarySection
                        quickReviewSection
                        deckSection
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Flashcards")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text("Review important terms from your AI lecture notes")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.secondaryText)
        }
    }

    private var summarySection: some View {
        HStack(spacing: 16) {
            FlashcardMetricCard(
                title: "Total Cards",
                value: "\(allFlashcards.count)",
                token: AppPalette.noteTokens[4]
            )

            FlashcardMetricCard(
                title: "Decks",
                value: "\(totalDecks)",
                token: AppPalette.noteTokens[0]
            )
        }
    }

    private var quickReviewSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Quick Review", systemImage: "sparkles")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)

            if allFlashcards.isEmpty {
                emptyStateCard(
                    title: "No flashcards yet",
                    message: "Generate a lecture note first, then the app will create flashcards for review."
                )
            } else {
                NavigationLink {
                    FlashcardReviewView(
                        flashcards: allFlashcards,
                        deckTitle: "All Flashcards"
                    )
                } label: {
                    FlashcardDeckCard(
                        title: "All Flashcards",
                        subtitle: "\(totalDecks) decks across \(coursesWithFlashcards.count) courses",
                        count: allFlashcards.count,
                        token: AppPalette.noteTokens[4]
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var deckSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            if !coursesWithFlashcards.isEmpty {
                Label("By Course", systemImage: "books.vertical")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)
            }

            ForEach(coursesWithFlashcards) { course in
                VStack(alignment: .leading, spacing: 12) {
                    Text(course.title)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.ink)

                    ForEach(course.notesWithFlashcards) { note in
                        NavigationLink {
                            FlashcardReviewView(
                                flashcards: note.flashcards,
                                deckTitle: note.title
                            )
                        } label: {
                            FlashcardDeckCard(
                                title: note.title,
                                subtitle: note.createdAt.formatted(date: .abbreviated, time: .shortened),
                                count: note.flashcards.count,
                                token: AppPalette.noteToken(for: note.title)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func emptyStateCard(title: String, message: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)

            Text(message)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .appCard()
    }
}

private struct FlashcardMetricCard: View {
    let title: String
    let value: String
    let token: AppVisualToken

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            AppIconTile(token: token, size: 58)

            Text(title)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.secondaryText)

            Text(value)
                .font(.system(size: 27, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .appCard()
    }
}

private struct FlashcardDeckCard: View {
    let title: String
    let subtitle: String
    let count: Int
    let token: AppVisualToken

    var body: some View {
        HStack(spacing: 16) {
            AppIconTile(token: token, size: 68)

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(2)

                Text(subtitle)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.secondaryText)

                AppPill(text: "\(count) cards", color: token.tint)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(AppTheme.secondaryText)
        }
        .padding(18)
        .appCard()
    }
}

private extension Course {
    var notesWithFlashcards: [LectureNote] {
        notes
            .filter { !$0.flashcards.isEmpty }
            .sorted { $0.createdAt > $1.createdAt }
    }
}

#Preview {
    FlashcardLibraryPreview()
        .modelContainer(for: [
            Course.self,
            LectureNote.self,
            Flashcard.self,
            QuizQuestion.self
        ], inMemory: true)
}

private struct FlashcardLibraryPreview: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Course.createdAt, order: .reverse) private var courses: [Course]
    @State private var hasSeeded = false

    var body: some View {
        FlashcardLibraryView()
            .task {
                guard !hasSeeded, courses.isEmpty else { return }

                let iosCourse = Course(title: "iOS App Development")
                let uiNote = LectureNote(
                    title: "Week 12 - SwiftUI Navigation",
                    markdown: "# SwiftUI Navigation"
                )
                uiNote.flashcards = [
                    Flashcard(term: "NavigationStack", definitionText: "A container that manages a navigation path in SwiftUI.", example: "Push CourseDetailView from CourseListView."),
                    Flashcard(term: "TabView", definitionText: "A container that switches between multiple top-level pages.", example: "Dashboard, Courses, Flashcards, Settings.")
                ]
                iosCourse.notes.append(uiNote)

                let aiCourse = Course(title: "Artificial Intelligence")
                let mlNote = LectureNote(
                    title: "Lecture 5 - Search Algorithms",
                    markdown: "# Search Algorithms"
                )
                mlNote.flashcards = [
                    Flashcard(term: "BFS", definitionText: "Breadth-first search explores nodes level by level.", example: "Useful for finding the shortest path in an unweighted graph.")
                ]
                aiCourse.notes.append(mlNote)

                modelContext.insert(iosCourse)
                modelContext.insert(aiCourse)
                try? modelContext.save()

                hasSeeded = true
            }
    }
}
