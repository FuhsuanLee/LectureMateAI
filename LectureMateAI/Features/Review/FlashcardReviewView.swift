//
//  FlashcardReviewView.swift
//  LectureMateAI
//
//  Created by Sherry Lee on 2026/6/3.
//

import SwiftUI
import TipKit

struct FlashcardReviewView: View {
    let flashcards: [Flashcard]

    @State private var currentIndex = 0
    @State private var isFlipped = false

    private let tip = FlashcardTip()

    var body: some View {
        VStack(spacing: 24) {
            TipView(tip)

            if flashcards.isEmpty {
                ContentUnavailableView(
                    "No Flashcards",
                    systemImage: "rectangle.on.rectangle",
                    description: Text("Generate notes first to create flashcards.")
                )
            } else {
                Text("\(currentIndex + 1) / \(flashcards.count)")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                FlashcardView(
                    flashcard: flashcards[currentIndex],
                    isFlipped: isFlipped
                )
                .onTapGesture {
                    withAnimation(.spring) {
                        isFlipped.toggle()
                    }
                }

                HStack {
                    Button("Previous") {
                        movePrevious()
                    }
                    .disabled(currentIndex == 0)

                    Spacer()

                    Button("Next") {
                        moveNext()
                    }
                    .disabled(currentIndex == flashcards.count - 1)
                }
                .padding(.horizontal)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Flashcards")
    }

    private func movePrevious() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
        isFlipped = false
    }

    private func moveNext() {
        guard currentIndex < flashcards.count - 1 else { return }
        currentIndex += 1
        isFlipped = false
    }
}

struct FlashcardView: View {
    let flashcard: Flashcard
    let isFlipped: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(.thinMaterial)
                .shadow(radius: 8)

            VStack(spacing: 18) {
                if isFlipped {
                    Text(flashcard.definitionText)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)

                    Text("Example: \(flashcard.example)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                } else {
                    Text(flashcard.term)
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Tap to reveal definition")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .frame(height: 280)
        .rotation3DEffect(
            .degrees(isFlipped ? 180 : 0),
            axis: (x: 0, y: 1, z: 0)
        )
    }
}
