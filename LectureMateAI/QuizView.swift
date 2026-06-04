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

    var body: some View {
        List {
            if questions.isEmpty {
                ContentUnavailableView(
                    "No Quiz",
                    systemImage: "questionmark.circle",
                    description: Text("Generate notes first to create quiz questions.")
                )
            } else {
                ForEach(questions) { question in
                    QuizQuestionCard(question: question) {
                        try? modelContext.save()
                    }
                }
            }
        }
        .navigationTitle("Quiz")
    }
}

struct QuizQuestionCard: View {
    let question: QuizQuestion
    let onAnswer: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(question.question)
                .font(.headline)

            ForEach(question.options.indices, id: \.self) { index in
                Button {
                    question.selectedIndex = index
                    onAnswer()
                } label: {
                    HStack {
                        Text(question.options[index])
                            .foregroundStyle(.primary)

                        Spacer()

                        if question.selectedIndex == index {
                            Image(systemName: question.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(question.isCorrect ? .green : .red)
                        }
                    }
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }

            if question.isAnswered {
                Text(question.explanation)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 8)
    }
}
