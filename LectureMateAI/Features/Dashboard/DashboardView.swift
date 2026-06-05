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

    private var displayName: String {
        let rawValue = authManager.username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !rawValue.isEmpty else { return "Student" }

        let candidate = rawValue.split(separator: "@").first.map(String.init) ?? rawValue
        return candidate
            .replacingOccurrences(of: ".", with: " ")
            .split(separator: " ")
            .map { $0.capitalized }
            .joined(separator: " ")
    }

    private var firstName: String {
        displayName.split(separator: " ").first.map(String.init) ?? displayName
    }

    var body: some View {
        NavigationStack {
            AppBackground {
                AppScrollPage {
                    VStack(alignment: .leading, spacing: 24) {
                        headerSection
                        heroSection
                        statsSection
                        recentNotesSection
                        progressSection
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var headerSection: some View {
        HStack(alignment: .center, spacing: 16) {
            HStack(spacing: 14) {
                LectureMateLogoMark(size: 58)

                VStack(alignment: .leading, spacing: 4) {
                    Text("LectureMate AI")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Text("Your AI Study Partner")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.secondaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
            }

            Spacer()

            AppAvatarBadge(name: displayName, size: 56)
        }
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Hi \(firstName) 👋")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text("Ready to turn lectures into knowledge?")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.secondaryText)

            Button(action: onCreateNote) {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                    Text("New Note")
                }
            }
            .buttonStyle(AppPrimaryButtonStyle())
            .frame(maxWidth: 230)
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
                footnote: "Courses in your semester",
                token: AppPalette.courseTokens[5]
            )

            DashboardStatCard(
                title: "Total Notes",
                value: "\(totalNotes)",
                footnote: "AI notes generated",
                token: AppPalette.noteTokens[1]
            )

            DashboardStatCard(
                title: "Flashcards",
                value: "\(totalFlashcards)",
                footnote: "Quick review cards",
                token: AppPalette.noteTokens[4]
            )

            DashboardStatCard(
                title: "Quiz Accuracy",
                value: "\(Int(accuracy * 100))%",
                footnote: "Correct answers so far",
                token: AppPalette.noteTokens[3]
            )
        }
    }

    private var recentNotesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Recent Notes", systemImage: "doc.text")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)

                Spacer()

                Text("Latest")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.blue)
            }

            VStack(spacing: 0) {
                if recentNotes.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("No lecture notes yet")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.ink)

                        Text("Create your first course, import a lecture, and your recent notes will appear here.")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(22)
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
                                .padding(.horizontal, 22)
                        }
                    }
                }
            }
            .appCard()
        }
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Label("Your Learning Progress", systemImage: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)

                Spacer()

                Text("This Week")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.blue)
            }

            HStack(alignment: .center, spacing: 24) {
                ProgressRing(progress: overallProgress, lineWidth: 14)
                    .frame(width: 124, height: 124)

                VStack(spacing: 18) {
                    ProgressMetricRow(
                        title: "Notes Created",
                        detail: "\(totalNotes) total",
                        progress: min(Double(totalNotes) / 8.0, 1),
                        color: AppTheme.blue
                    )

                    ProgressMetricRow(
                        title: "Flashcards Ready",
                        detail: "\(totalFlashcards) cards",
                        progress: min(Double(totalFlashcards) / 30.0, 1),
                        color: AppTheme.mint
                    )

                    ProgressMetricRow(
                        title: "Quiz Accuracy",
                        detail: "\(Int(accuracy * 100))%",
                        progress: accuracy,
                        color: AppTheme.purple
                    )
                }
            }

            Text(totalNotes == 0 ? "Add your first lecture to start building study momentum." : "Great job! Your lecture archive is growing steadily.")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.blue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(AppTheme.blue.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .padding(22)
        .appCard()
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
    let footnote: String
    let token: AppVisualToken

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            AppIconTile(token: token, size: 52)

            Text(title)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.secondaryText)

            Text(value)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)

            Text(footnote)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(token.tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .appCard()
    }
}

private struct DashboardRecentNoteRow: View {
    let item: DashboardRecentNote

    var body: some View {
        let token = AppPalette.noteToken(for: item.note.title)

        HStack(spacing: 16) {
            AppIconTile(token: token, size: 64)

            VStack(alignment: .leading, spacing: 8) {
                Text(item.note.title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(2)

                Text("\(item.courseTitle) • \(item.note.createdAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.secondaryText)

                HStack(spacing: 8) {
                    AppPill(text: "AI Notes", color: AppTheme.blue)

                    if !item.note.flashcards.isEmpty {
                        AppPill(text: "Flashcards", color: AppTheme.purple)
                    }

                    if !item.note.quizQuestions.isEmpty {
                        AppPill(text: "Quiz", color: AppTheme.orange)
                    }
                }
            }

            Spacer()
        }
        .padding(18)
    }
}

private struct ProgressMetricRow: View {
    let title: String
    let detail: String
    let progress: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)

                Spacer()

                Text(detail)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.secondaryText)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(color.opacity(0.12))

                    Capsule()
                        .fill(color)
                        .frame(width: geometry.size.width * max(0, min(progress, 1)))
                }
            }
            .frame(height: 8)
        }
    }
}
