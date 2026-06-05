//
//  AppTheme.swift
//  LectureMateAI
//
//  Created by Codex on 2026/6/5.
//

import SwiftUI
import UIKit

// Feature tint colors. System colors adapt to light/dark mode and
// accessibility settings automatically. The brand blue lives in the
// AccentColor asset and is used via Color.accentColor / .tint.
enum AppTheme {
    static let notes = Color.teal
    static let flashcards = Color.purple
    static let quiz = Color.orange
}

// Deterministic icon + tint pairing so a course or note keeps a stable,
// distinct visual identity everywhere it appears.
struct AppVisualToken {
    let icon: String
    let tint: Color
}

enum AppPalette {
    static let courseTokens: [AppVisualToken] = [
        AppVisualToken(icon: "book.closed.fill", tint: .blue),
        AppVisualToken(icon: "function", tint: .indigo),
        AppVisualToken(icon: "atom", tint: .purple),
        AppVisualToken(icon: "chart.bar.fill", tint: .orange),
        AppVisualToken(icon: "brain.head.profile", tint: .pink),
        AppVisualToken(icon: "globe.americas.fill", tint: .teal)
    ]

    static let noteTokens: [AppVisualToken] = [
        AppVisualToken(icon: "waveform", tint: .purple),
        AppVisualToken(icon: "doc.text.fill", tint: .teal),
        AppVisualToken(icon: "play.rectangle.fill", tint: .blue),
        AppVisualToken(icon: "target", tint: .orange),
        AppVisualToken(icon: "rectangle.on.rectangle", tint: .indigo)
    ]

    static func courseToken(for seed: String) -> AppVisualToken {
        token(from: seed, tokens: courseTokens)
    }

    static func noteToken(for seed: String) -> AppVisualToken {
        token(from: seed, tokens: noteTokens)
    }

    static func token(from seed: String, tokens: [AppVisualToken]) -> AppVisualToken {
        let sum = seed.unicodeScalars.reduce(0) { partialResult, scalar in
            partialResult + Int(scalar.value)
        }

        return tokens[sum % tokens.count]
    }
}

// Brand logo mark, used on the login screen and dashboard header.
struct LectureMateLogoMark: View {
    @ScaledMetric(relativeTo: .body) private var size: CGFloat = 60

    init(size: CGFloat = 60) {
        self._size = ScaledMetric(wrappedValue: size, relativeTo: .body)
    }

    var body: some View {
        Image(systemName: "book.pages.fill")
            .font(.system(size: size * 0.5, weight: .medium))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(
                Color.accentColor,
                in: RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
            )
            .accessibilityHidden(true)
    }
}

// Settings-app-style icon badge: a solid tinted rounded square with a white
// SF Symbol. Scales with Dynamic Type.
struct AppIconBadge: View {
    let icon: String
    let tint: Color

    @ScaledMetric(relativeTo: .body) private var size: CGFloat = 30

    init(icon: String, tint: Color, size: CGFloat = 30) {
        self.icon = icon
        self.tint = tint
        self._size = ScaledMetric(wrappedValue: size, relativeTo: .body)
    }

    init(token: AppVisualToken, size: CGFloat = 30) {
        self.init(icon: token.icon, tint: token.tint, size: size)
    }

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: size * 0.55, weight: .medium))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(
                tint,
                in: RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
            )
            .accessibilityHidden(true)
    }
}

// Circular monogram avatar for the signed-in user.
struct AppAvatarBadge: View {
    let name: String

    @ScaledMetric(relativeTo: .body) private var size: CGFloat = 44

    init(name: String, size: CGFloat = 44) {
        self.name = name
        self._size = ScaledMetric(wrappedValue: size, relativeTo: .body)
    }

    var body: some View {
        Text(initials(from: name))
            .font(.system(size: size * 0.4, weight: .semibold))
            .foregroundStyle(Color.accentColor)
            .frame(width: size, height: size)
            .background(Color.accentColor.opacity(0.15), in: Circle())
            .accessibilityHidden(true)
    }

    private func initials(from value: String) -> String {
        let source = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !source.isEmpty else { return "AI" }

        let parts = source
            .replacingOccurrences(of: "@", with: " ")
            .replacingOccurrences(of: ".", with: " ")
            .split(separator: " ")

        let letters = parts.prefix(2).compactMap { part in
            part.first.map { String($0).uppercased() }
        }

        if !letters.isEmpty {
            return letters.joined()
        }

        return String(source.prefix(2)).uppercased()
    }
}

// Circular progress indicator with a percentage readout. Scales with
// Dynamic Type so the inner labels never outgrow the ring.
struct ProgressRing: View {
    let progress: Double
    var lineWidth: CGFloat = 10

    @ScaledMetric(relativeTo: .title3) private var size: CGFloat = 110

    init(progress: Double, size: CGFloat = 110, lineWidth: CGFloat = 10) {
        self.progress = progress
        self.lineWidth = lineWidth
        self._size = ScaledMetric(wrappedValue: size, relativeTo: .title3)
    }

    private var clampedProgress: Double {
        max(0, min(progress, 1))
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(.quaternary, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: clampedProgress)
                .stroke(
                    Color.accentColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 2) {
                Text(clampedProgress, format: .percent.precision(.fractionLength(0)))
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primary)

                Text("Progress")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int(clampedProgress * 100)) percent")
    }
}

extension View {
    // Inset-grouped-style card for screens that use ScrollView instead of
    // List. Pair with a Color(.systemGroupedBackground) page background.
    func cardBackground() -> some View {
        self.background(
            Color(uiColor: .secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
    }
}
