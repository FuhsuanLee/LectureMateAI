//
//  AppTheme.swift
//  LectureMateAI
//
//  Created by Codex on 2026/6/5.
//

import SwiftUI

enum AppTheme {
    static let ink = Color(red: 0.05, green: 0.11, blue: 0.28)
    static let secondaryText = Color(red: 0.42, green: 0.48, blue: 0.63)
    static let blue = Color(red: 0.14, green: 0.45, blue: 0.98)
    static let cyan = Color(red: 0.13, green: 0.82, blue: 0.82)
    static let purple = Color(red: 0.52, green: 0.35, blue: 0.97)
    static let mint = Color(red: 0.18, green: 0.80, blue: 0.64)
    static let orange = Color(red: 0.98, green: 0.58, blue: 0.19)
    static let red = Color(red: 0.97, green: 0.34, blue: 0.38)
    static let pageTop = Color(red: 0.97, green: 0.99, blue: 1.0)
    static let pageBottom = Color.white
    static let cardFill = Color.white.opacity(0.93)
    static let cardBorder = Color.white.opacity(0.84)
    static let softShadow = Color.black.opacity(0.07)

    static let primaryGradient = LinearGradient(
        colors: [blue, cyan],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let coolGradient = LinearGradient(
        colors: [purple.opacity(0.95), blue],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let mintGradient = LinearGradient(
        colors: [mint, cyan],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let pageGradient = LinearGradient(
        colors: [pageTop, pageBottom],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct AppVisualToken {
    let icon: String
    let tint: Color
    let gradient: LinearGradient
    let softTint: Color
}

enum AppPalette {
    static let courseTokens: [AppVisualToken] = [
        AppVisualToken(icon: "swift", tint: AppTheme.blue, gradient: AppTheme.primaryGradient, softTint: AppTheme.blue.opacity(0.14)),
        AppVisualToken(icon: "iphone", tint: AppTheme.mint, gradient: AppTheme.mintGradient, softTint: AppTheme.mint.opacity(0.16)),
        AppVisualToken(icon: "chevron.left.forwardslash.chevron.right", tint: AppTheme.purple, gradient: AppTheme.coolGradient, softTint: AppTheme.purple.opacity(0.16)),
        AppVisualToken(icon: "cylinder.split.1x2", tint: AppTheme.orange, gradient: LinearGradient(colors: [AppTheme.orange, AppTheme.red.opacity(0.85)], startPoint: .leading, endPoint: .trailing), softTint: AppTheme.orange.opacity(0.16)),
        AppVisualToken(icon: "brain.head.profile", tint: AppTheme.purple, gradient: LinearGradient(colors: [AppTheme.purple, AppTheme.cyan], startPoint: .leading, endPoint: .trailing), softTint: AppTheme.purple.opacity(0.14)),
        AppVisualToken(icon: "books.vertical", tint: AppTheme.blue, gradient: LinearGradient(colors: [AppTheme.blue, AppTheme.purple.opacity(0.9)], startPoint: .leading, endPoint: .trailing), softTint: AppTheme.blue.opacity(0.14))
    ]

    static let noteTokens: [AppVisualToken] = [
        AppVisualToken(icon: "waveform", tint: AppTheme.purple, gradient: AppTheme.coolGradient, softTint: AppTheme.purple.opacity(0.14)),
        AppVisualToken(icon: "doc.text", tint: AppTheme.mint, gradient: AppTheme.mintGradient, softTint: AppTheme.mint.opacity(0.14)),
        AppVisualToken(icon: "play.rectangle", tint: AppTheme.blue, gradient: AppTheme.primaryGradient, softTint: AppTheme.blue.opacity(0.14)),
        AppVisualToken(icon: "target", tint: AppTheme.orange, gradient: LinearGradient(colors: [AppTheme.orange, AppTheme.red.opacity(0.9)], startPoint: .leading, endPoint: .trailing), softTint: AppTheme.orange.opacity(0.14)),
        AppVisualToken(icon: "rectangle.on.rectangle", tint: AppTheme.purple, gradient: AppTheme.coolGradient, softTint: AppTheme.purple.opacity(0.14))
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

struct AppBackground<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            AppTheme.pageGradient
                .ignoresSafeArea()

            Circle()
                .fill(AppTheme.blue.opacity(0.14))
                .frame(width: 360, height: 360)
                .blur(radius: 70)
                .offset(x: -120, y: -300)

            Circle()
                .fill(AppTheme.purple.opacity(0.12))
                .frame(width: 320, height: 320)
                .blur(radius: 70)
                .offset(x: 150, y: -220)

            Circle()
                .fill(Color.white.opacity(0.95))
                .frame(width: 540, height: 540)
                .blur(radius: 18)
                .offset(y: 320)

            content
        }
    }
}

struct AppScrollPage<Content: View>: View {
    private let horizontalPadding: CGFloat
    private let topPadding: CGFloat
    private let bottomPadding: CGFloat
    private let showsIndicators: Bool
    private let content: Content

    init(
        horizontalPadding: CGFloat = 20,
        topPadding: CGFloat = 20,
        bottomPadding: CGFloat = 120,
        showsIndicators: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.horizontalPadding = horizontalPadding
        self.topPadding = topPadding
        self.bottomPadding = bottomPadding
        self.showsIndicators = showsIndicators
        self.content = content()
    }

    var body: some View {
        ScrollView(showsIndicators: showsIndicators) {
            VStack(alignment: .leading, spacing: 0) {
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, topPadding)
            .padding(.bottom, bottomPadding)
        }
        .contentMargins(.horizontal, horizontalPadding, for: .scrollContent)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct LectureMateLogoMark: View {
    var size: CGFloat = 72

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(AppTheme.primaryGradient)
                .frame(width: size, height: size)
                .shadow(color: AppTheme.blue.opacity(0.22), radius: 18, x: 0, y: 12)

            Image(systemName: "book.pages.fill")
                .font(.system(size: size * 0.38, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)

            Image(systemName: "sparkles")
                .font(.system(size: size * 0.18, weight: .bold))
                .foregroundStyle(.white)
                .padding(size * 0.14)
        }
    }
}

struct AppAvatarBadge: View {
    let name: String
    var size: CGFloat = 62

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.88, green: 0.86, blue: 1.0), Color(red: 0.78, green: 0.90, blue: 1.0)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .shadow(color: AppTheme.softShadow, radius: 18, x: 0, y: 12)

            Text(initials(from: name))
                .font(.system(size: size * 0.26, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)
        }
        .overlay(
            Circle()
                .stroke(Color.white.opacity(0.9), lineWidth: 3)
        )
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

struct AppIconTile: View {
    let token: AppVisualToken
    var size: CGFloat = 78

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(token.softTint)
                .frame(width: size, height: size)

            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .stroke(Color.white.opacity(0.85), lineWidth: 1)
                .frame(width: size, height: size)

            Image(systemName: token.icon)
                .font(.system(size: size * 0.34, weight: .semibold, design: .rounded))
                .foregroundStyle(token.gradient)
        }
    }
}

struct AppPill: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}

struct AppPrimaryButtonStyle: ButtonStyle {
    var gradient: LinearGradient = AppTheme.primaryGradient

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(gradient)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(0.28), lineWidth: 1)
            )
            .shadow(color: AppTheme.blue.opacity(configuration.isPressed ? 0.14 : 0.22), radius: configuration.isPressed ? 8 : 18, x: 0, y: configuration.isPressed ? 4 : 12)
            .scaleEffect(configuration.isPressed ? 0.985 : 1.0)
    }
}

struct AppSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .semibold, design: .rounded))
            .foregroundStyle(AppTheme.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(AppTheme.cardFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.white.opacity(0.82), lineWidth: 1)
            )
            .shadow(color: AppTheme.softShadow, radius: configuration.isPressed ? 8 : 16, x: 0, y: configuration.isPressed ? 4 : 10)
            .scaleEffect(configuration.isPressed ? 0.99 : 1.0)
    }
}

struct ProgressRing: View {
    let progress: Double
    var lineWidth: CGFloat = 14

    var body: some View {
        ZStack {
            Circle()
                .stroke(AppTheme.blue.opacity(0.10), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: max(0, min(progress, 1)))
                .stroke(
                    AppTheme.primaryGradient,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 4) {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)

                Text("Progress")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
    }
}

extension View {
    func appCard(cornerRadius: CGFloat = 28) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(AppTheme.cardFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(AppTheme.cardBorder, lineWidth: 1)
                    )
                    .shadow(color: AppTheme.softShadow, radius: 22, x: 0, y: 12)
            )
    }

    func appInputField() -> some View {
        self
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.86))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(AppTheme.blue.opacity(0.10), lineWidth: 1)
                    )
            )
    }
}
