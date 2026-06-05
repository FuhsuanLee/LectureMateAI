//
//  DashboardView.swift
//  LectureMateAI
//
//  Created by Sherry Lee on 2026/6/3.
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @EnvironmentObject private var authManager: AuthManager
    @Query private var courses: [Course]

    var onCreateNote: () -> Void = {}

    private var totalNotes: Int {
        courses.flatMap(\.notes).count
    }

    private var totalFlashcards: Int {
        courses.flatMap(\.notes).flatMap(\.flashcards).count
    }

    private var totalQuiz: Int {
        courses.flatMap(\.notes).flatMap(\.quizQuestions).count
    }

    private var correctQuiz: Int {
        courses
            .flatMap(\.notes)
            .flatMap(\.quizQuestions)
            .filter(\.isCorrect)
            .count
    }

    private var accuracy: Double {
        guard totalQuiz > 0 else { return 0 }
        return Double(correctQuiz) / Double(totalQuiz)
    }

    private var recentNotes: [DashboardRecentNote] {
        courses
            .flatMap { course in
                course.notes.map { note in
                    DashboardRecentNote(note: note, courseTitle: course.title)
                }
            }
            .sorted { $0.note.createdAt > $1.note.createdAt }
            .prefix(3)
            .map { $0 }
    }

    private var overallProgress: Double {
        let notesProgress = min(Double(totalNotes) / 8.0, 1)
        let flashcardProgress = min(Double(totalFlashcards) / 30.0, 1)
        return min((notesProgress + flashcardProgress + accuracy) / 3.0, 1)
    }

    private var firstName: String {
        let displayName = authManager.displayName
        return displayName.split(separator: " ").first.map(String.init) ?? displayName
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    greetingSection
                    statsSection
                    recentNotesSection
                    progressSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Dashboard")
        }
    }

    private var greetingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Hi \(firstName)")
                .font(.title2.weight(.bold))

            Text("Ready to turn lectures into knowledge?")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button(action: onCreateNote) {
                Label("New Note", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 4)
        }
    }

    private var statsSection: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ],
            spacing: 16
        ) {
            DashboardStatCard(
                title: "Total Courses",
                value: "\(courses.count)",
                token: AppPalette.courseTokens[0]
            )

            DashboardStatCard(
                title: "Total Notes",
                value: "\(totalNotes)",
                token: AppVisualToken(icon: "doc.text.fill", tint: AppTheme.notes)
            )

            DashboardStatCard(
                title: "Flashcards",
                value: "\(totalFlashcards)",
                token: AppVisualToken(icon: "rectangle.on.rectangle", tint: AppTheme.flashcards)
            )

            DashboardStatCard(
                title: "Quiz Accuracy",
                value: "\(Int(accuracy * 100))%",
                token: AppVisualToken(icon: "target", tint: AppTheme.quiz)
            )
        }
    }

    private var recentNotesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Notes")
                .font(.title3.weight(.semibold))

            VStack(spacing: 0) {
                if recentNotes.isEmpty {
                    ContentUnavailableView(
                        "No Notes Yet",
                        systemImage: "doc.text",
                        description: Text("Create your first course, import a lecture, and your recent notes will appear here.")
                    )
                } else {
                    ForEach(Array(recentNotes.enumerated()), id: \.element.id) { index, item in
                        NavigationLink {
                            NoteDetailView(note: item.note)
                        } label: {
                            DashboardRecentNoteRow(item: item)
                        }
                        .buttonStyle(.plain)

                        if index < recentNotes.count - 1 {
                            Divider()
                                .padding(.leading, 64)
                        }
                    }
                }
            }
            .cardBackground()
        }
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Learning Progress")
                .font(.title3.weight(.semibold))

            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .center, spacing: 20) {
                    ProgressRing(progress: overallProgress)

                    VStack(spacing: 14) {
                        ProgressMetricRow(
                            title: "Notes Created",
                            detail: "\(totalNotes) total",
                            progress: min(Double(totalNotes) / 8.0, 1),
                            tint: Color.accentColor
                        )

                        ProgressMetricRow(
                            title: "Flashcards Ready",
                            detail: "\(totalFlashcards) card\(totalFlashcards == 1 ? "" : "s")",
                            progress: min(Double(totalFlashcards) / 30.0, 1),
                            tint: AppTheme.flashcards
                        )

                        ProgressMetricRow(
                            title: "Quiz Accuracy",
                            detail: "\(Int(accuracy * 100))%",
                            progress: accuracy,
                            tint: AppTheme.quiz
                        )
                    }
                }

                Text(totalNotes == 0 ? "Add your first lecture to start building study momentum." : "Great job! Your lecture archive is growing steadily.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .cardBackground()
        }
    }
}

private struct DashboardRecentNote: Identifiable {
    let note: LectureNote
    let courseTitle: String

    var id: PersistentIdentifier {
        note.persistentModelID
    }
}

private struct DashboardStatCard: View {
    let title: String
    let value: String
    let token: AppVisualToken

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AppIconBadge(token: token, size: 30)

            Text(value)
                .font(.title.weight(.bold))
                .monospacedDigit()

            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(16)
        .cardBackground()
    }
}

private struct DashboardRecentNoteRow: View {
    let item: DashboardRecentNote

    var body: some View {
        HStack(spacing: 12) {
            AppIconBadge(token: AppPalette.noteToken(for: item.note.title), size: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.note.title)
                    .font(.headline)
                    .lineLimit(2)

                Text("\(item.courseTitle) • \(item.note.createdAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color(uiColor: .tertiaryLabel))
        }
        .padding(16)
    }
}

private struct ProgressMetricRow: View {
    let title: String
    let detail: String
    let progress: Double
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.subheadline)

                Spacer()

                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            ProgressView(value: progress)
                .tint(tint)
        }
    }
}
