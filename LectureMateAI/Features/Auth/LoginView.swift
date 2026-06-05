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
        ScrollView {
            VStack(spacing: 24) {
                branding
                fields
                loginButton
                orDivider
                appleButton
                signUpRow
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 48)
            .contentShape(Rectangle())
            .onTapGesture {
                focusedField = nil
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var branding: some View {
        VStack(spacing: 12) {
            LectureMateLogoMark(size: 72)

            Text("LectureMate AI")
                .font(.largeTitle.weight(.bold))

            Text("Turn lectures into smart study notes.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }

    private var fields: some View {
        VStack(spacing: 12) {
            inputRow(systemImage: "envelope") {
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

            inputRow(systemImage: "lock") {
                SecureField("Password", text: $password)
                    .focused($focusedField, equals: .password)
                    .submitLabel(.go)
                    .onSubmit {
                        submitLogin()
                    }
            }

            Button("Forgot password?") { }
                .font(.subheadline)
                .foregroundStyle(.tint)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private var loginButton: some View {
        Button(action: submitLogin) {
            Text("Log In")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(!canLogin)
    }

    private var orDivider: some View {
        HStack(spacing: 12) {
            VStack { Divider() }

            Text("or")
                .font(.footnote)
                .foregroundStyle(.secondary)

            VStack { Divider() }
        }
    }

    private var appleButton: some View {
        Button { } label: {
            Label("Continue with Apple", systemImage: "apple.logo")
                .font(.body.weight(.semibold))
                .foregroundStyle(Color(uiColor: .systemBackground))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    Color.primary,
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                )
        }
        .buttonStyle(.plain)
    }

    private var signUpRow: some View {
        HStack(spacing: 4) {
            Text("Don't have an account?")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button("Sign Up") { }
                .font(.subheadline.weight(.semibold))
        }
        .frame(maxWidth: .infinity)
    }

    private func inputRow<Content: View>(
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(.secondary)

            content()
                .font(.body)
        }
        .padding(14)
        .background(
            Color(uiColor: .secondarySystemBackground),
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
    }

    private func submitLogin() {
        guard canLogin else { return }
        focusedField = nil
        authManager.login(email: email, password: password)
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthManager())
}
