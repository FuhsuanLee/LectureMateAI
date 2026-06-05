//
//  QuizView.swift
//  LectureMateAI
//
//  Created by Sherry Lee on 2026/6/3.
//

import SwiftUI
import SwiftData

struct QuizView: View {
    @Environment(\.modelContext) private var modelContext

    let questions: [QuizQuestion]

    @State private var currentIndex = 0

    private var currentQuestion: QuizQuestion? {
        guard questions.indices.contains(currentIndex) else { return nil }
        return questions[currentIndex]
    }

    private var correctAnswers: Int {
        questions.filter(\.isCorrect).count
    }

    var body: some View {
        AppBackground {
            VStack(spacing: 22) {
                if questions.isEmpty {
                    VStack(spacing: 16) {
                        Text("No Quiz Yet")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.ink)

                        Text("Generate notes first to create quiz questions.")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    .padding(24)
                    .appCard(cornerRadius: 30)
                } else if let currentQuestion {
                    progressSection
                    questionCard(question: currentQuestion)
                    Spacer(minLength: 0)
                } else {
                    summaryCard
                    Spacer(minLength: 0)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 36)
        }
        .navigationTitle("Quiz")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Question \(currentIndex + 1) of \(questions.count)")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)

            HStack(spacing: 12) {
                ForEach(questions.indices, id: \.self) { index in
                    Capsule()
                        .fill(index <= currentIndex ? AnyShapeStyle(AppTheme.primaryGradient) : AnyShapeStyle(AppTheme.blue.opacity(0.10)))
                        .frame(height: 8)
                }
            }
        }
    }

    private func questionCard(question: QuizQuestion) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 10) {
                AppPill(text: "AI Quiz", color: AppTheme.purple)
                Spacer()
            }

            Text(question.question)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)

            VStack(spacing: 14) {
                ForEach(question.options.indices, id: \.self) { index in
                    Button {
                        answer(question, with: index)
                    } label: {
                        QuizOptionRow(
                            letter: optionLetter(for: index),
                            text: question.options[index],
                            isSelected: question.selectedIndex == index,
                            isCorrect: question.correctIndex == index && question.isAnswered,
                            isAnswered: question.isAnswered
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            if question.isAnswered {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 10) {
                        AppIconTile(token: AppPalette.noteTokens[1], size: 56)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Explanation")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.ink)

                            Text(question.isCorrect ? "Nice work, you got it right." : "Review the concept before moving on.")
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                    }

                    Text(question.explanation)
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.secondaryText)

                    Button(currentIndex == questions.count - 1 ? "Finish Quiz" : "Next Question") {
                        goToNextQuestion()
                    }
                    .buttonStyle(AppPrimaryButtonStyle())
                }
                .padding(20)
                .background(AppTheme.mint.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            }
        }
        .padding(24)
        .appCard(cornerRadius: 32)
    }

    private var summaryCard: some View {
        VStack(spacing: 18) {
            ProgressRing(
                progress: questions.isEmpty ? 0 : Double(correctAnswers) / Double(questions.count),
                lineWidth: 16
            )
            .frame(width: 180, height: 180)

            Text("Quiz Complete")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)

            Text("You answered \(correctAnswers) out of \(questions.count) questions correctly.")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.secondaryText)
                .multilineTextAlignment(.center)

            Button("Restart Quiz") {
                for question in questions {
                    question.selectedIndex = nil
                }

                try? modelContext.save()
                currentIndex = 0
            }
            .buttonStyle(AppPrimaryButtonStyle())
        }
        .padding(24)
        .appCard(cornerRadius: 32)
    }

    private func answer(_ question: QuizQuestion, with index: Int) {
        question.selectedIndex = index
        try? modelContext.save()
    }

    private func goToNextQuestion() {
        if currentIndex < questions.count - 1 {
            currentIndex += 1
        } else {
            currentIndex = questions.count
        }
    }

    private func optionLetter(for index: Int) -> String {
        let letters = ["A", "B", "C", "D", "E", "F"]
        return letters.indices.contains(index) ? letters[index] : "\(index + 1)"
    }
}

private struct QuizOptionRow: View {
    let letter: String
    let text: String
    let isSelected: Bool
    let isCorrect: Bool
    let isAnswered: Bool

    private var borderColor: Color {
        if isSelected {
            return isCorrect ? AppTheme.mint : AppTheme.blue
        }

        return AppTheme.blue.opacity(0.10)
    }

    private var fillColor: Color {
        if isSelected {
            return isCorrect ? AppTheme.mint.opacity(0.10) : AppTheme.blue.opacity(0.08)
        }

        return Color.white.opacity(0.75)
    }

    var body: some View {
        HStack(spacing: 18) {
            Text(letter)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(isSelected ? .white : AppTheme.ink)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(isSelected ? AnyShapeStyle(AppTheme.primaryGradient) : AnyShapeStyle(AppTheme.blue.opacity(0.08)))
                )

            Text(text)
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.ink)
                .multilineTextAlignment(.leading)

            Spacer()

            if isSelected {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(isCorrect ? AppTheme.mint : AppTheme.red)
            } else if isAnswered && isCorrect {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(AppTheme.mint)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background(fillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(borderColor, lineWidth: isSelected ? 2 : 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}
