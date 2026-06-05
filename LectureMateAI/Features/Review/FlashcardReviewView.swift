//
//  FlashcardReviewView.swift
//  LectureMateAI
//
//  Created by Sherry Lee on 2026/6/3.
//

import SwiftUI

struct FlashcardReviewView: View {
    let flashcards: [Flashcard]
    let deckTitle: String

    @State private var orderedFlashcards: [Flashcard] = []
    @State private var currentIndex = 0
    @State private var isFlipped = false

    init(flashcards: [Flashcard], deckTitle: String = "Flashcards") {
        self.flashcards = flashcards
        self.deckTitle = deckTitle
    }

    private var currentFlashcard: Flashcard? {
        guard orderedFlashcards.indices.contains(currentIndex) else { return nil }
        return orderedFlashcards[currentIndex]
    }

    private var progress: Double {
        guard !orderedFlashcards.isEmpty else { return 0 }
        return Double(currentIndex + 1) / Double(orderedFlashcards.count)
    }

    private var reviewedCount: Int {
        guard !orderedFlashcards.isEmpty else { return 0 }
        return currentIndex + 1
    }

    private var remainingCount: Int {
        max(orderedFlashcards.count - reviewedCount, 0)
    }

    var body: some View {
        AppBackground {
            VStack(spacing: 24) {
                if orderedFlashcards.isEmpty {
                    VStack(spacing: 16) {
                        Text("No Flashcards")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.ink)

                        Text("Generate notes first to create flashcards.")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    .padding(24)
                    .appCard(cornerRadius: 30)
                } else {
                    progressSection
                    flashcardStack
                    controlsSection
                    statsSection
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 36)
        }
        .navigationTitle(deckTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if orderedFlashcards.isEmpty {
                orderedFlashcards = flashcards
            }
        }
    }

    private var progressSection: some View {
        VStack(spacing: 14) {
            HStack {
                ProgressView(value: progress)
                    .tint(AppTheme.blue)

                Text("\(currentIndex + 1) / \(orderedFlashcards.count)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.secondaryText)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.7))
                    .clipShape(Capsule())
            }
        }
    }

    private var flashcardStack: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(AppTheme.purple.opacity(0.07))
                .frame(height: 520)
                .rotationEffect(.degrees(-4))
                .offset(x: -10, y: 10)

            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(AppTheme.blue.opacity(0.07))
                .frame(height: 520)
                .rotationEffect(.degrees(3))
                .offset(x: 8, y: -4)

            if let currentFlashcard {
                FlashcardFaceView(
                    flashcard: currentFlashcard,
                    isFlipped: isFlipped
                )
                .onTapGesture {
                    flipCard()
                }
            }
        }
    }

    private var controlsSection: some View {
        HStack(spacing: 22) {
            Button {
                movePrevious()
            } label: {
                VStack(spacing: 10) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 24, weight: .bold))
                    Text("Previous")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(AppTheme.blue)
                .frame(width: 110, height: 110)
                .background(Color.white.opacity(0.86))
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(currentIndex == 0)
            .opacity(currentIndex == 0 ? 0.45 : 1.0)

            Button {
                flipCard()
            } label: {
                VStack(spacing: 10) {
                    Image(systemName: "arrow.2.squarepath")
                        .font(.system(size: 28, weight: .bold))
                    Text("Flip")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                }
                .foregroundStyle(.white)
                .frame(width: 124, height: 124)
                .background(Circle().fill(AppTheme.primaryGradient))
                .shadow(color: AppTheme.blue.opacity(0.22), radius: 18, x: 0, y: 12)
            }
            .buttonStyle(.plain)

            Button {
                moveNext()
            } label: {
                VStack(spacing: 10) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 24, weight: .bold))
                    Text("Next")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(AppTheme.blue)
                .frame(width: 110, height: 110)
                .background(Color.white.opacity(0.86))
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(currentIndex == orderedFlashcards.count - 1)
            .opacity(currentIndex == orderedFlashcards.count - 1 ? 0.45 : 1.0)
        }
    }

    private var statsSection: some View {
        HStack(spacing: 14) {
            FlashcardStatPill(
                title: "Reviewed",
                value: "\(reviewedCount)",
                color: AppTheme.mint
            )

            FlashcardStatPill(
                title: "Remaining",
                value: "\(remainingCount)",
                color: AppTheme.orange
            )

            Button {
                shuffleDeck()
            } label: {
                VStack(spacing: 6) {
                    Text("Shuffle")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.purple)

                    Image(systemName: "shuffle")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(AppTheme.purple)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(AppTheme.purple.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private func flipCard() {
        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            isFlipped.toggle()
        }
    }

    private func movePrevious() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
        isFlipped = false
    }

    private func moveNext() {
        guard currentIndex < orderedFlashcards.count - 1 else { return }
        currentIndex += 1
        isFlipped = false
    }

    private func shuffleDeck() {
        guard !orderedFlashcards.isEmpty else { return }
        orderedFlashcards.shuffle()
        currentIndex = 0
        isFlipped = false
    }
}

private struct FlashcardFaceView: View {
    let flashcard: Flashcard
    let isFlipped: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(Color.white.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                        .stroke(Color.white.opacity(0.86), lineWidth: 1)
                )
                .shadow(color: AppTheme.softShadow, radius: 24, x: 0, y: 14)

            frontView
                .opacity(isFlipped ? 0 : 1)

            backView
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                .opacity(isFlipped ? 1 : 0)
        }
        .frame(height: 520)
        .rotation3DEffect(
            .degrees(isFlipped ? 180 : 0),
            axis: (x: 0, y: 1, z: 0)
        )
        .animation(.spring(response: 0.45, dampingFraction: 0.82), value: isFlipped)
    }

    private var frontView: some View {
        VStack(spacing: 22) {
            HStack {
                AppIconTile(token: AppPalette.noteTokens[4], size: 58)
                Spacer()
                Image(systemName: "bookmark")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(AppTheme.purple)
            }

            Spacer()

            Text(flashcard.term)
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)
                .multilineTextAlignment(.center)

            RoundedRectangle(cornerRadius: 999, style: .continuous)
                .fill(AppTheme.coolGradient)
                .frame(width: 110, height: 5)

            Text("Tap to flip")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.secondaryText)

            Spacer()

            Label("Tap card to reveal the definition", systemImage: "hand.tap")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.blue)
        }
        .padding(28)
    }

    private var backView: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                AppPill(text: "Definition", color: AppTheme.blue)
                Spacer()
            }

            Text(flashcard.definitionText)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)

            if !flashcard.example.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Example")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.mint)

                    Text(flashcard.example)
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.secondaryText)
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.mint.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            }

            Spacer()

            Text("Tap the card again to go back")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.purple)
        }
        .padding(28)
    }
}

private struct FlashcardStatPill: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(color)

            Text(title)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(color.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
