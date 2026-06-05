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

    var body: some View {
        List {
            Section("Notes") {
                ForEach(course.notes.sorted(by: { $0.createdAt > $1.createdAt })) { note in
                    NavigationLink {
                        NoteDetailView(note: note)
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(note.title)
                                .font(.headline)

                            Text(note.createdAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle(course.title)
        .toolbar {
            NavigationLink {
                FileImportGenerateView(course: course)
            } label: {
                Image(systemName: "sparkles")
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
