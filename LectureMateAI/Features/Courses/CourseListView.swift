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
            AppBackground {
                AppScrollPage(topPadding: 22) {
                    VStack(alignment: .leading, spacing: 22) {
                        headerSection
                        searchBar
                        courseCardsSection

                        if !courses.isEmpty {
                            footerBanner
                        }
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showAddCourse) {
                addCourseSheet
            }
        }
    }

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Courses")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text("All your courses in one place")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.secondaryText)
            }

            Spacer()

            Button {
                newCourseTitle = ""
                showAddCourse = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: 58, height: 58)
                    .background(Circle().fill(AppTheme.primaryGradient))
                    .shadow(color: AppTheme.blue.opacity(0.22), radius: 18, x: 0, y: 12)
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 14) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(AppTheme.secondaryText)

            TextField("Search courses...", text: $searchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.ink)
        }
        .appInputField()
        .appCard(cornerRadius: 28)
    }

    private var courseCardsSection: some View {
        LazyVStack(spacing: 16) {
            if filteredCourses.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text(courses.isEmpty ? "No courses yet" : "No matching course")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.ink)

                    Text(courses.isEmpty ? "Tap the plus button to create your first course." : "Try a different keyword or create a new course.")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .appCard()
            } else {
                ForEach(filteredCourses) { course in
                    NavigationLink {
                        CourseDetailView(course: course)
                    } label: {
                        CourseListCard(course: course)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            deleteCourse(course)
                        } label: {
                            Label("Delete Course", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }

    private var footerBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(AppTheme.blue)

            Text("Keep learning! You have \(courses.count) course\(courses.count == 1 ? "" : "s") this semester.")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.blue)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(AppTheme.blue.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var addCourseSheet: some View {
        NavigationStack {
            AppBackground {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("New Course")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.ink)

                        Text("Create a course first, then start importing lecture notes inside it.")
                            .font(.system(size: 17, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.secondaryText)
                    }

                    TextField("Course title", text: $newCourseTitle)
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.ink)
                        .focused($isNewCourseFocused)
                        .appInputField()

                    HStack(spacing: 14) {
                        Button("Cancel") {
                            newCourseTitle = ""
                            showAddCourse = false
                        }
                        .buttonStyle(AppSecondaryButtonStyle())

                        Button("Add Course") {
                            addCourse()
                        }
                        .buttonStyle(AppPrimaryButtonStyle())
                        .disabled(newCourseTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .opacity(newCourseTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.72 : 1.0)
                    }
                }
                .padding(24)
                .appCard(cornerRadius: 32)
                .padding(24)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        isNewCourseFocused = true
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .presentationDetents([.height(340)])
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

private struct CourseListCard: View {
    let course: Course

    private var noteCountText: String {
        "\(course.notes.count) note\(course.notes.count == 1 ? "" : "s")"
    }

    private var updatedText: String {
        let latestDate = course.notes.map(\.createdAt).max() ?? course.createdAt
        return latestDate.formatted(date: .abbreviated, time: .omitted)
    }

    var body: some View {
        let token = AppPalette.courseToken(for: course.title)

        HStack(spacing: 18) {
            AppIconTile(token: token, size: 74)

            VStack(alignment: .leading, spacing: 10) {
                Text(course.title)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(2)

                HStack(spacing: 12) {
                    Label(noteCountText, systemImage: "doc.plaintext")
                    Text("Updated \(updatedText)")
                }
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.secondaryText)

                AppPill(text: "AI Lecture Notes", color: token.tint)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(AppTheme.secondaryText)
        }
        .padding(18)
        .appCard()
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
