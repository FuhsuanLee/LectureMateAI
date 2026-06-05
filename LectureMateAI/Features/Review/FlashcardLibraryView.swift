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
            List {
                if !allFlashcards.isEmpty {
                    summarySection
                    courseSections
                }
            }
            .navigationTitle("Flashcards")
            .overlay {
                if allFlashcards.isEmpty {
                    ContentUnavailableView(
                        "No Flashcards",
                        systemImage: "rectangle.on.rectangle",
                        description: Text("Generate a lecture note first, then the app will create flashcards for review.")
                    )
                }
            }
        }
    }

    private var summarySection: some View {
        Section {
            NavigationLink {
                FlashcardReviewView(
                    flashcards: allFlashcards,
                    deckTitle: "All Flashcards"
                )
            } label: {
                HStack(spacing: 12) {
                    AppIconBadge(
                        icon: "rectangle.on.rectangle",
                        tint: AppTheme.flashcards,
                        size: 36
                    )

                    VStack(alignment: .leading, spacing: 2) {
                        Text("All Flashcards")
                            .font(.headline)

                        Text("\(allFlashcards.count) card\(allFlashcards.count == 1 ? "" : "s") across \(totalDecks) deck\(totalDecks == 1 ? "" : "s")")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var courseSections: some View {
        ForEach(coursesWithFlashcards) { course in
            Section(course.title) {
                ForEach(course.notesWithFlashcards) { note in
                    NavigationLink {
                        FlashcardReviewView(
                            flashcards: note.flashcards,
                            deckTitle: note.title
                        )
                    } label: {
                        HStack(spacing: 12) {
                            AppIconBadge(
                                token: AppPalette.noteToken(for: note.title),
                                size: 36
                            )

                            VStack(alignment: .leading, spacing: 2) {
                                Text(note.title)
                                    .font(.headline)
                                    .lineLimit(2)

                                Text(note.createdAt.formatted(date: .abbreviated, time: .omitted))
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Text("\(note.flashcards.count)")
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                    }
                }
            }
        }
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
