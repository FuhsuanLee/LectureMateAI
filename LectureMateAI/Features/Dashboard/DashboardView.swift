//
//  DashboardView.swift
//  LectureMateAI
//
//  Created by Sherry Lee on 2026/6/3.
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query private var courses: [Course]

    private var totalNotes: Int {
        courses.flatMap { $0.notes }.count
    }

    private var totalFlashcards: Int {
        courses.flatMap { $0.notes }.flatMap { $0.flashcards }.count
    }

    private var totalQuiz: Int {
        courses.flatMap { $0.notes }.flatMap { $0.quizQuestions }.count
    }

    private var correctQuiz: Int {
        courses
            .flatMap { $0.notes }
            .flatMap { $0.quizQuestions }
            .filter { $0.isCorrect }
            .count
    }

    private var accuracy: Double {
        guard totalQuiz > 0 else { return 0 }
        return Double(correctQuiz) / Double(totalQuiz)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Welcome back")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("Track your learning progress here.")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        DashboardCard(
                            title: "Courses",
                            value: "\(courses.count)",
                            icon: "books.vertical.fill"
                        )

                        DashboardCard(
                            title: "Notes",
                            value: "\(totalNotes)",
                            icon: "doc.text.fill"
                        )

                        DashboardCard(
                            title: "Flashcards",
                            value: "\(totalFlashcards)",
                            icon: "rectangle.on.rectangle.fill"
                        )

                        DashboardCard(
                            title: "Quiz Accuracy",
                            value: "\(Int(accuracy * 100))%",
                            icon: "checkmark.circle.fill"
                        )
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Learning Progress")
                            .font(.headline)

                        ProgressView(value: accuracy)
                            .animation(.easeInOut, value: accuracy)

                        Text("Complete more quizzes to improve your progress.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                }
                .padding()
            }
            .navigationTitle("Dashboard")
        }
    }
}

struct DashboardCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)

            Text(value)
                .font(.largeTitle)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}
