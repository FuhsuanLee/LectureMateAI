//
//  LoginView.swift
//  LectureMateAI
//
//  Created by Sherry Lee on 2026/6/3.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var authManager: AuthManager

    @State private var isSigningIn = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            AppBackground {
                AppScrollPage(topPadding: 24, bottomPadding: 48) {
                    VStack(spacing: 28) {
                        topBranding
                        heroCard
                        loginCard
                    }
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .toolbar(.hidden, for: .navigationBar)
            .alert("Sign-in failed", isPresented: errorAlertBinding) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    private var topBranding: some View {
        VStack(spacing: 18) {
            HStack(spacing: 16) {
                LectureMateLogoMark(size: 68)

                VStack(alignment: .leading, spacing: 4) {
                    Text("LectureMate AI")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Text("Your AI Study Partner")
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 10) {
                Text("Welcome back! 👋")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)

                Text("Turn lectures into smart study notes.")
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
    }

    private var heroCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.75),
                            AppTheme.blue.opacity(0.09),
                            AppTheme.purple.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 260)
                .frame(maxWidth: .infinity)

            Circle()
                .fill(AppTheme.blue.opacity(0.08))
                .frame(width: 180, height: 180)
                .offset(x: -110, y: 12)

            Circle()
                .fill(AppTheme.purple.opacity(0.08))
                .frame(width: 132, height: 132)
                .offset(x: 120, y: -50)

            VStack(spacing: 18) {
                HStack(spacing: 14) {
                    floatingHeroTile(icon: "waveform", gradient: AppTheme.coolGradient)
                    floatingHeroTile(icon: "doc.text", gradient: AppTheme.mintGradient)
                }
                .offset(y: 8)

                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.white.opacity(0.9))
                        .frame(width: 150, height: 112)
                        .rotationEffect(.degrees(-8))

                    Image(systemName: "book.pages.fill")
                        .font(.system(size: 46, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.primaryGradient)
                }
                .shadow(color: AppTheme.softShadow, radius: 20, x: 0, y: 12)

                HStack(spacing: 16) {
                    floatingHeroTile(icon: "rectangle.on.rectangle", gradient: AppTheme.coolGradient)
                    floatingHeroTile(icon: "target", gradient: LinearGradient(colors: [AppTheme.orange, AppTheme.red], startPoint: .leading, endPoint: .trailing))
                }
            }
        }
        .appCard(cornerRadius: 34)
    }

    private var loginCard: some View {
        VStack(spacing: 16) {
            Button(action: signInWithGitHub) {
                HStack(spacing: 12) {
                    if isSigningIn {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "chevron.left.forwardslash.chevron.right")
                    }
                    Text(isSigningIn ? "Signing in…" : "Continue with GitHub")
                }
            }
            .buttonStyle(AppPrimaryButtonStyle())
            .disabled(isSigningIn)
            .opacity(isSigningIn ? 0.72 : 1.0)

            Text("Sign in with your GitHub account to get started.")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .appCard(cornerRadius: 32)
    }

    private func floatingHeroTile(icon: String, gradient: LinearGradient) -> some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(Color.white.opacity(0.84))
            .frame(width: 82, height: 64)
            .overlay {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(gradient)
            }
            .shadow(color: AppTheme.softShadow, radius: 16, x: 0, y: 10)
    }

    private func signInWithGitHub() {
        guard !isSigningIn else { return }
        isSigningIn = true
        Task {
            let service = GitHubOAuthService()
            do {
                let profile = try await service.signIn()
                authManager.completeGitHubLogin(
                    token: profile.token,
                    username: profile.username,
                    displayName: profile.displayName,
                    avatarURL: profile.avatarURL
                )
            } catch GitHubOAuthError.canceled {
                // User dismissed the sheet; stay on the login screen silently.
            } catch {
                errorMessage = error.localizedDescription
            }
            isSigningIn = false
        }
    }
}
