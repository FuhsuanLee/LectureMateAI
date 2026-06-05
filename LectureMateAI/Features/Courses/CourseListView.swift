//
//  CourseListView.swift
//  LectureMateAI
//
//  Created by Sherry Lee on 2026/6/3.
//

import SwiftUI
import SwiftData

struct CourseListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Course.createdAt, order: .reverse) private var courses: [Course]

    @State private var showAddCourse = false
    @State private var newCourseTitle = ""

    var body: some View {
        NavigationStack {
            List {
                if courses.isEmpty {
                    Text("No courses yet")
                        .foregroundStyle(.secondary)
                }

                ForEach(courses) { course in
                    NavigationLink {
                        CourseDetailView(course: course)
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(course.title)
                                .font(.headline)

                            Text("\(course.notes.count) notes")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete(perform: deleteCourse)
            }
            .navigationTitle("Courses")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddCourse = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddCourse) {
                NavigationStack {
                    Form {
                        TextField("Course title", text: $newCourseTitle)
                    }
                    .navigationTitle("New Course")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                newCourseTitle = ""
                                showAddCourse = false
                            }
                        }

                        ToolbarItem(placement: .confirmationAction) {
                            Button("Add") {
                                addCourse()
                            }
                            .disabled(newCourseTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                }
            }
        }
    }

    private func addCourse() {
        let title = newCourseTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }

        let course = Course(title: title)
        modelContext.insert(course)

        do {
            try modelContext.save()
            print("Course saved successfully:", title)
            print("Courses count after save:", courses.count)
        } catch {
            print("Failed to save course:", error)
        }

        newCourseTitle = ""
        showAddCourse = false
    }

    private func deleteCourse(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(courses[index])
        }

        do {
            try modelContext.save()
        } catch {
            print("Failed to delete course:", error.localizedDescription)
        }
    }
}

#Preview {
    CourseListViewPreview()
        .modelContainer(for: [
            Course.self,
            LectureNote.self,
            Flashcard.self,
            QuizQuestion.self
        ], inMemory: true)
}

private struct CourseListViewPreview: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Course.createdAt, order: .reverse) private var courses: [Course]
    @State private var hasSeeded = false

    var body: some View {
        CourseListView()
            .task {
                guard !hasSeeded, courses.isEmpty else { return }

                let course = Course(title: "iOS App Development")
                let note = LectureNote(
                    title: "Week 12 - SwiftUI Navigation",
                    markdown: "# Preview Note\n\n## Summary\nThis is a preview lecture note."
                )

                course.notes.append(note)
                modelContext.insert(course)

                try? modelContext.save()
                hasSeeded = true
            }
    }
}
