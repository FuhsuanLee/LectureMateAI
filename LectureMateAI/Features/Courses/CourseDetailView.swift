//
//  CourseDetailView.swift
//  LectureMateAI
//
//  Created by Sherry Lee on 2026/6/3.
//

import SwiftUI
import SwiftData

struct CourseDetailView: View {
    let course: Course

    private var sortedNotes: [LectureNote] {
        course.notes.sorted(by: { $0.createdAt > $1.createdAt })
    }

    private var latestDateText: String {
        let latestDate = sortedNotes.first?.createdAt ?? course.createdAt
        return latestDate.formatted(date: .abbreviated, time: .omitted)
    }

    var body: some View {
        List {
            Section {
                summaryRow

                NavigationLink {
                    FileImportGenerateView(course: course)
                } label: {
                    Label("New Lecture Note", systemImage: "plus")
                        .foregroundStyle(.tint)
                }
            }

            Section("Lecture Notes") {
                if sortedNotes.isEmpty {
                    ContentUnavailableView(
                        "No Lecture Notes",
                        systemImage: "doc.text",
                        description: Text("Tap “New Lecture Note” to upload lecture audio and slides for this course.")
                    )
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(sortedNotes) { note in
                        NavigationLink {
                            NoteDetailView(note: note)
                        } label: {
                            CourseNoteRow(note: note)
                        }
                    }
                }
            }
        }
        .navigationTitle(course.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    FileImportGenerateView(course: course)
                } label: {
                    Image(systemName: "sparkles")
                }
                .accessibilityLabel("New Lecture Note")
            }
        }
    }

    private var summaryRow: some View {
        HStack(spacing: 12) {
            AppIconBadge(token: AppPalette.courseToken(for: course.title), size: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(course.title)
                    .font(.headline)
                    .lineLimit(2)

                Text("\(course.notes.count) note\(course.notes.count == 1 ? "" : "s") • Updated \(latestDateText)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct CourseNoteRow: View {
    let note: LectureNote

    private var subtitle: String {
        var parts = [note.createdAt.formatted(date: .abbreviated, time: .omitted)]

        if !note.flashcards.isEmpty {
            parts.append("\(note.flashcards.count) flashcard\(note.flashcards.count == 1 ? "" : "s")")
        }

        if !note.quizQuestions.isEmpty {
            parts.append("\(note.quizQuestions.count) quiz question\(note.quizQuestions.count == 1 ? "" : "s")")
        }

        return parts.joined(separator: " • ")
    }

    var body: some View {
        HStack(spacing: 12) {
            AppIconBadge(token: AppPalette.noteToken(for: note.title), size: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(note.title)
                    .font(.headline)
                    .lineLimit(2)

                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        CourseDetailView(course: previewCourse)
    }
    .modelContainer(for: [
        Course.self,
        LectureNote.self,
        Flashcard.self,
        QuizQuestion.self
    ], inMemory: true)
}

private var previewCourse: Course {
    let course = Course(title: "Machine Learning")

    let note1 = LectureNote(
        title: "Lecture 5 - Neural Networks",
        markdown: """
        # Neural Networks

        ## Summary
        - Introduced perceptrons
        - Explained backpropagation
        """
    )

    let note2 = LectureNote(
        title: "Lecture 6 - Overfitting",
        markdown: """
        # Overfitting

        ## Summary
        - Training loss can be misleading
        - Validation data is important
        """
    )

    course.notes = [note1, note2]
    return course
}
