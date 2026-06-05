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
        AppBackground {
            AppScrollPage(bottomPadding: 44) {
                VStack(alignment: .leading, spacing: 22) {
                    summaryCard
                    notesHeader
                    notesSection
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
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(AppTheme.primaryGradient))
                }
            }
        }
    }

    private var summaryCard: some View {
        let token = AppPalette.courseToken(for: course.title)

        return VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .center, spacing: 16) {
                AppIconTile(token: token, size: 78)

                VStack(alignment: .leading, spacing: 8) {
                    Text(course.title)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.ink)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)

                    HStack(spacing: 8) {
                        AppPill(text: "\(course.notes.count) notes", color: AppTheme.blue)
                        AppPill(text: "Updated \(latestDateText)", color: AppTheme.secondaryText)
                    }
                }
            }

            NavigationLink {
                FileImportGenerateView(course: course)
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                    Text("New Lecture Note")
                }
            }
            .buttonStyle(AppPrimaryButtonStyle())
        }
        .padding(20)
        .appCard(cornerRadius: 32)
    }

    private var notesHeader: some View {
        HStack {
            Label("Lecture Notes", systemImage: "doc.text")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)

            Spacer()

            Text("Newest First")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.secondaryText)
        }
    }

    private var notesSection: some View {
        LazyVStack(spacing: 16) {
            if sortedNotes.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("No lecture notes yet")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.ink)

                    Text("Tap “New Lecture Note” to upload lecture audio and slides for this course.")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .appCard()
            } else {
                ForEach(sortedNotes) { note in
                    NavigationLink {
                        NoteDetailView(note: note)
                    } label: {
                        CourseNoteCard(note: note)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct CourseNoteCard: View {
    let note: LectureNote

    var body: some View {
        let token = AppPalette.noteToken(for: note.title)

        HStack(spacing: 16) {
            AppIconTile(token: token, size: 70)

            VStack(alignment: .leading, spacing: 10) {
                Text(note.title)
                    .font(.system(size: 23, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(2)

                Text(note.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.secondaryText)

                HStack(spacing: 8) {
                    AppPill(text: "AI Notes", color: AppTheme.blue)

                    if !note.flashcards.isEmpty {
                        AppPill(text: "Flashcards \(note.flashcards.count)", color: AppTheme.purple)
                    }

                    if !note.quizQuestions.isEmpty {
                        AppPill(text: "Quiz \(note.quizQuestions.count)", color: AppTheme.orange)
                    }
                }
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
