//
//  LoginView.swift
//  LectureMateAI
//
//  Created by Sherry Lee on 2026/6/3.
//

import SwiftUI

private enum LoginField {
    case email
    case password
}

struct LoginView: View {
    @EnvironmentObject private var authManager: AuthManager

    @State private var email = ""
    @State private var password = ""
    @FocusState private var focusedField: LoginField?

    private var canLogin: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            AppBackground {
                AppScrollPage(topPadding: 24, bottomPadding: 48) {
                    VStack(spacing: 28) {
                        topBranding
                        heroCard
                        loginCard
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        focusedField = nil
                    }
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
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
        VStack(spacing: 20) {
            inputRow(systemImage: "envelope", placeholder: "Email address") {
                TextField("Email address", text: $email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .email)
                    .submitLabel(.next)
                    .onSubmit {
                        focusedField = .password
                    }
            }

            inputRow(systemImage: "lock", placeholder: "Password") {
                SecureField("Password", text: $password)
                    .focused($focusedField, equals: .password)
                    .submitLabel(.go)
                    .onSubmit {
                        submitLogin()
                    }
            }

            HStack {
                Spacer()

                Text("Forgot password?")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.blue)
            }

            Button(action: submitLogin) {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles")
                    Text("Login")
                }
            }
            .buttonStyle(AppPrimaryButtonStyle())
            .disabled(!canLogin)
            .opacity(canLogin ? 1.0 : 0.72)

            HStack {
                Rectangle()
                    .fill(AppTheme.blue.opacity(0.10))
                    .frame(height: 1)

                Text("or")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.secondaryText)
                    .padding(.horizontal, 12)

                Rectangle()
                    .fill(AppTheme.blue.opacity(0.10))
                    .frame(height: 1)
            }

            Button { } label: {
                HStack(spacing: 12) {
                    Image(systemName: "apple.logo")
                    Text("Continue with Apple")
                }
            }
            .buttonStyle(AppSecondaryButtonStyle())

            HStack(spacing: 6) {
                Text("Don't have an account?")
                    .foregroundStyle(AppTheme.secondaryText)

                Text("Sign up")
                    .foregroundStyle(AppTheme.blue)
            }
            .font(.system(size: 17, weight: .semibold, design: .rounded))
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

    private func inputRow<Content: View>(
        systemImage: String,
        placeholder: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AppTheme.blue)
                .frame(width: 26)

            content()
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.ink)
        }
        .appInputField()
    }

    private func submitLogin() {
        guard canLogin else { return }
        focusedField = nil
        authManager.login(email: email, password: password)
    }
}
