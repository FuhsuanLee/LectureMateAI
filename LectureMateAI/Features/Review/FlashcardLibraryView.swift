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
            .flatMap { $0.notes }
            .flatMap { $0.flashcards }
    }

    private var totalDecks: Int {
        coursesWithFlashcards
            .flatMap { $0.notes }
            .filter { !$0.flashcards.isEmpty }
            .count
    }

    var body: some View {
        NavigationStack {
            List {
                if allFlashcards.isEmpty {
                    ContentUnavailableView(
                        "No Flashcards Yet",
                        systemImage: "rectangle.on.rectangle.slash",
                        description: Text("Generate a lecture note first, then the app will create flashcards for review.")
                    )
                } else {
                    Section {
                        NavigationLink {
                            FlashcardReviewView(
                                flashcards: allFlashcards,
                                deckTitle: "All Flashcards"
                            )
                        } label: {
                            FlashcardDeckRow(
                                title: "All Flashcards",
                                subtitle: "\(totalDecks) decks across \(coursesWithFlashcards.count) courses",
                                count: allFlashcards.count,
                                systemImage: "square.stack.3d.up.fill",
                                tint: .blue
                            )
                        }
                    } header: {
                        Text("Quick Review")
                    }

                    ForEach(coursesWithFlashcards) { course in
                        Section(course.title) {
                            ForEach(course.notesWithFlashcards) { note in
                                NavigationLink {
                                    FlashcardReviewView(
                                        flashcards: note.flashcards,
                                        deckTitle: note.title
                                    )
                                } label: {
                                    FlashcardDeckRow(
                                        title: note.title,
                                        subtitle: note.createdAt.formatted(date: .abbreviated, time: .shortened),
                                        count: note.flashcards.count,
                                        systemImage: "rectangle.stack.fill",
                                        tint: .orange
                                    )
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Flashcards")
        }
    }
}

private struct FlashcardDeckRow: View {
    let title: String
    let subtitle: String
    let count: Int
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(tint.opacity(0.14))
                    .frame(width: 46, height: 46)

                Image(systemName: systemImage)
                    .font(.headline)
                    .foregroundStyle(tint)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(count)")
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.thinMaterial)
                .clipShape(Capsule())
        }
        .padding(.vertical, 4)
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
