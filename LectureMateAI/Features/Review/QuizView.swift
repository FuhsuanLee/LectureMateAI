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
        Group {
            if questions.isEmpty {
                ContentUnavailableView(
                    "No Quiz Yet",
                    systemImage: "target",
                    description: Text("Generate notes first to create quiz questions.")
                )
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        if let currentQuestion {
                            progressSection
                            questionCard(question: currentQuestion)
                        } else {
                            summaryCard
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Quiz")
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Question \(currentIndex + 1) of \(questions.count)")
                .font(.headline)
                .monospacedDigit()

            ProgressView(value: Double(currentIndex), total: Double(questions.count))
                .tint(AppTheme.quiz)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func questionCard(question: QuizQuestion) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(question.question)
                .font(.title3.weight(.semibold))

            VStack(spacing: 12) {
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
                    .disabled(question.isAnswered)
                }
            }

            if question.isAnswered {
                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Explanation")
                        .font(.headline)

                    Text(question.isCorrect ? "Nice work, you got it right." : "Review the concept before moving on.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Text(question.explanation)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                Button {
                    goToNextQuestion()
                } label: {
                    Text(currentIndex == questions.count - 1 ? "Finish Quiz" : "Next Question")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardBackground()
    }

    private var summaryCard: some View {
        VStack(spacing: 16) {
            ProgressRing(
                progress: questions.isEmpty ? 0 : Double(correctAnswers) / Double(questions.count),
                size: 140
            )

            Text("Quiz Complete")
                .font(.title2.weight(.bold))

            Text("You answered \(correctAnswers) out of \(questions.count) questions correctly.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Restart Quiz") {
                for question in questions {
                    question.selectedIndex = nil
                }

                try? modelContext.save()
                currentIndex = 0
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .cardBackground()
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

    @ScaledMetric(relativeTo: .body) private var letterSize: CGFloat = 32

    // Green for the right pick, red for the wrong one. Selection only
    // happens at answer time, so a selected row is always answered.
    private var selectionTint: Color {
        isCorrect ? .green : .red
    }

    private var rowFill: Color {
        if isCorrect {
            return Color.green.opacity(0.15)
        }

        if isSelected {
            return Color.red.opacity(0.15)
        }

        return Color(uiColor: .tertiarySystemFill)
    }

    private var borderColor: Color {
        isSelected ? selectionTint : Color(uiColor: .separator)
    }

    private var statusDescription: String {
        if isSelected {
            return isCorrect ? "Correct" : "Incorrect"
        }

        if isAnswered && isCorrect {
            return "Correct answer"
        }

        return ""
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(letter)
                .font(.headline)
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .frame(width: letterSize, height: letterSize)
                .background(
                    isSelected ? selectionTint : Color(uiColor: .tertiarySystemFill),
                    in: Circle()
                )

            Text(text)
                .font(.body)
                .multilineTextAlignment(.leading)

            Spacer()

            if isSelected {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(isCorrect ? Color.green : Color.red)
            } else if isAnswered && isCorrect {
                Image(systemName: "checkmark.circle")
                    .font(.title3)
                    .foregroundStyle(.green)
            }
        }
        .padding(12)
        .background(rowFill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(borderColor, lineWidth: isSelected ? 2 : 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Option \(letter): \(text)")
        .accessibilityValue(statusDescription)
    }
}

#Preview {
    NavigationStack {
        QuizView(questions: [
            QuizQuestion(
                question: "哪一個排序法平均時間複雜度是 O(n log n)？",
                options: ["Bubble Sort", "Selection Sort", "Merge Sort", "Insertion Sort"],
                correctIndex: 2,
                explanation: "Merge Sort 採用分治法，平均與最壞情況都能維持 O(n log n)。"
            ),
            QuizQuestion(
                question: "Which container manages a navigation path in SwiftUI?",
                options: ["TabView", "NavigationStack", "List", "ScrollView"],
                correctIndex: 1,
                explanation: "NavigationStack manages a stack of views pushed with NavigationLink."
            )
        ])
    }
    .modelContainer(for: [
        Course.self,
        LectureNote.self,
        Flashcard.self,
        QuizQuestion.self
    ], inMemory: true)
}
