//
//  FlashcardReviewView.swift
//  LectureMateAI
//
//  Created by Sherry Lee on 2026/6/3.
//

import SwiftUI
import SwiftData

// Value snapshot of a flashcard so the review deck never holds live SwiftData
// model references — deleting the source course or note elsewhere in the app
// cannot invalidate what this screen is showing.
private struct ReviewFlashcard: Identifiable {
    let id = UUID()
    let term: String
    let definitionText: String
    let example: String

    init(_ flashcard: Flashcard) {
        self.term = flashcard.term
        self.definitionText = flashcard.definitionText
        self.example = flashcard.example
    }
}

struct FlashcardReviewView: View {
    let flashcards: [Flashcard]
    let deckTitle: String

    @State private var orderedFlashcards: [ReviewFlashcard] = []
    @State private var currentIndex = 0
    @State private var isFlipped = false

    init(flashcards: [Flashcard], deckTitle: String = "Flashcards") {
        self.flashcards = flashcards
        self.deckTitle = deckTitle
    }

    private var currentFlashcard: ReviewFlashcard? {
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
        Group {
            if orderedFlashcards.isEmpty {
                ContentUnavailableView(
                    "No Flashcards",
                    systemImage: "rectangle.on.rectangle",
                    description: Text("Generate notes first to create flashcards.")
                )
            } else {
                VStack(spacing: 24) {
                    progressSection
                    flashcardSection
                    controlsSection
                    statsSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 24)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(deckTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    shuffleDeck()
                } label: {
                    Image(systemName: "shuffle")
                }
                .accessibilityLabel("Shuffle deck")
                .disabled(orderedFlashcards.isEmpty)
            }
        }
        .onAppear {
            if orderedFlashcards.isEmpty {
                orderedFlashcards = flashcards.map { ReviewFlashcard($0) }
            }
        }
    }

    private var progressSection: some View {
        HStack(spacing: 12) {
            ProgressView(value: progress)

            Text("\(currentIndex + 1) of \(orderedFlashcards.count)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }

    private var flashcardSection: some View {
        Group {
            if let currentFlashcard {
                FlashcardFaceView(
                    flashcard: currentFlashcard,
                    isFlipped: isFlipped
                )
                .onTapGesture {
                    flipCard()
                }
                .accessibilityAddTraits(.isButton)
                .accessibilityHint("Double tap to flip the card.")
            }
        }
    }

    private var controlsSection: some View {
        HStack(spacing: 16) {
            Button {
                movePrevious()
            } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.bordered)
            .accessibilityLabel("Previous card")
            .disabled(currentIndex == 0)

            Button {
                flipCard()
            } label: {
                Label("Flip", systemImage: "arrow.2.squarepath")
            }
            .buttonStyle(.borderedProminent)

            Button {
                moveNext()
            } label: {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.bordered)
            .accessibilityLabel("Next card")
            .disabled(currentIndex == orderedFlashcards.count - 1)
        }
        .controlSize(.large)
    }

    private var statsSection: some View {
        Text("\(reviewedCount) reviewed • \(remainingCount) remaining")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .monospacedDigit()
            .frame(maxWidth: .infinity)
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
    let flashcard: ReviewFlashcard
    let isFlipped: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.08), radius: 8, y: 2)

            frontView
                .opacity(isFlipped ? 0 : 1)

            backView
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                .opacity(isFlipped ? 1 : 0)
        }
        .frame(maxWidth: .infinity, minHeight: 320, maxHeight: 460)
        .rotation3DEffect(
            .degrees(isFlipped ? 180 : 0),
            axis: (x: 0, y: 1, z: 0)
        )
        .animation(.spring(response: 0.45, dampingFraction: 0.82), value: isFlipped)
    }

    private var frontView: some View {
        VStack(spacing: 16) {
            HStack {
                FlashcardFaceTag(text: "Term")
                Spacer()
            }

            Spacer()

            Text(flashcard.term)
                .font(.title.weight(.bold))
                .multilineTextAlignment(.center)

            Spacer()

            Text("Tap to flip")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(20)
    }

    private var backView: some View {
        VStack(alignment: .leading, spacing: 16) {
            FlashcardFaceTag(text: "Definition")

            // Definitions are unbounded AI output, so the body scrolls
            // rather than truncating inside the card's height cap.
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(flashcard.definitionText)
                        .font(.title3.weight(.semibold))

                    if !flashcard.example.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Example")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)

                            Text(flashcard.example)
                                .font(.callout)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            Color(uiColor: .tertiarySystemFill),
                            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
    }
}

// Small capsule tag identifying which face of the card is showing.
private struct FlashcardFaceTag: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(AppTheme.flashcards)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(AppTheme.flashcards.opacity(0.15), in: Capsule())
    }
}

#Preview {
    NavigationStack {
        FlashcardReviewView(
            flashcards: [
                Flashcard(
                    term: "NavigationStack",
                    definitionText: "A container that manages a navigation path in SwiftUI.",
                    example: "Push CourseDetailView from CourseListView."
                ),
                Flashcard(
                    term: "TabView",
                    definitionText: "A container that switches between multiple top-level pages.",
                    example: "Dashboard, Courses, Flashcards, Settings."
                )
            ],
            deckTitle: "SwiftUI Basics"
        )
    }
    .modelContainer(for: [
        Course.self,
        LectureNote.self,
        Flashcard.self,
        QuizQuestion.self
    ], inMemory: true)
}
