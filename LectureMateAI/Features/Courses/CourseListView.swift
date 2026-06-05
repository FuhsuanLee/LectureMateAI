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
    @State private var searchText = ""
    @FocusState private var isNewCourseFocused: Bool

    private var filteredCourses: [Course] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !query.isEmpty else { return courses }

        return courses.filter { course in
            course.title.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredCourses) { course in
                    NavigationLink {
                        CourseDetailView(course: course)
                    } label: {
                        CourseRow(course: course)
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            deleteCourse(course)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            deleteCourse(course)
                        } label: {
                            Label("Delete Course", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle("Courses")
            .searchable(text: $searchText, prompt: "Search courses")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        newCourseTitle = ""
                        showAddCourse = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("New Course")
                }
            }
            .overlay {
                if courses.isEmpty {
                    ContentUnavailableView(
                        "No Courses Yet",
                        systemImage: "book.closed",
                        description: Text("Tap the New Course button to create your first course.")
                    )
                } else if filteredCourses.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                }
            }
            .sheet(isPresented: $showAddCourse) {
                addCourseSheet
            }
        }
    }

    private var addCourseSheet: some View {
        NavigationStack {
            Form {
                TextField("Course title", text: $newCourseTitle)
                    .focused($isNewCourseFocused)
            }
            .navigationTitle("New Course")
            .navigationBarTitleDisplayMode(.inline)
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
            .onAppear {
                // Delay focus until the sheet finishes presenting so the
                // keyboard appears reliably.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    isNewCourseFocused = true
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func addCourse() {
        let title = newCourseTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }

        let course = Course(title: title)
        modelContext.insert(course)

        do {
            try modelContext.save()
        } catch {
            print("Failed to save course:", error)
        }

        newCourseTitle = ""
        showAddCourse = false
    }

    private func deleteCourse(_ course: Course) {
        modelContext.delete(course)

        do {
            try modelContext.save()
        } catch {
            print("Failed to delete course:", error.localizedDescription)
        }
    }
}

private struct CourseRow: View {
    let course: Course

    private var subtitleText: String {
        let noteCount = course.notes.count
        let latestDate = course.notes.map(\.createdAt).max() ?? course.createdAt
        let updatedText = latestDate.formatted(date: .abbreviated, time: .omitted)

        return "\(noteCount) note\(noteCount == 1 ? "" : "s") • Updated \(updatedText)"
    }

    var body: some View {
        HStack(spacing: 12) {
            AppIconBadge(token: AppPalette.courseToken(for: course.title), size: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(course.title)
                    .font(.headline)
                    .lineLimit(2)

                Text(subtitleText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
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
