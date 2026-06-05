//
//  SettingsView.swift
//  LectureMateAI
//
//  Created by Sherry Lee on 2026/6/3.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var authManager: AuthManager

    @State private var notificationsEnabled = true
    @State private var studyReminderEnabled = true

    private var displayName: String {
        let username = authManager.username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !username.isEmpty else { return "Guest Student" }

        return username.split(separator: "@").first.map(String.init) ?? username
    }

    var body: some View {
        NavigationStack {
            AppBackground {
                AppScrollPage(topPadding: 22) {
                    VStack(alignment: .leading, spacing: 22) {
                        headerSection
                        profileCard
                        preferencesCard
                        supportCard
                        logoutCard
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var headerSection: some View {
        Text("Settings")
            .font(.system(size: 40, weight: .bold, design: .rounded))
            .foregroundStyle(AppTheme.ink)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }

    private var profileCard: some View {
        HStack(spacing: 16) {
            AppAvatarBadge(name: displayName, size: 68)

            VStack(alignment: .leading, spacing: 6) {
                Text(displayName.capitalized)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(authManager.username.isEmpty ? "guest@lecturemate.ai" : authManager.username)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(AppTheme.secondaryText)
        }
        .padding(18)
        .appCard(cornerRadius: 30)
    }

    private var preferencesCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Preferences")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)

            VStack(spacing: 0) {
                SettingsToggleRow(
                    title: "Notifications",
                    subtitle: "Manage your notification preferences",
                    token: AppVisualToken(icon: "bell.fill", tint: AppTheme.purple, gradient: AppTheme.coolGradient, softTint: AppTheme.purple.opacity(0.14)),
                    isOn: $notificationsEnabled
                )

                Divider().padding(.leading, 72)

                SettingsToggleRow(
                    title: "Study Reminder",
                    subtitle: "Set study goals and reminders",
                    token: AppVisualToken(icon: "calendar.badge.clock", tint: AppTheme.mint, gradient: AppTheme.mintGradient, softTint: AppTheme.mint.opacity(0.14)),
                    isOn: $studyReminderEnabled
                )

                Divider().padding(.leading, 72)

                SettingsValueRow(
                    title: "Appearance",
                    subtitle: "Choose your app theme",
                    value: "Light",
                    token: AppVisualToken(icon: "paintpalette.fill", tint: AppTheme.orange, gradient: LinearGradient(colors: [AppTheme.orange, AppTheme.red], startPoint: .leading, endPoint: .trailing), softTint: AppTheme.orange.opacity(0.14))
                )

                Divider().padding(.leading, 72)

                SettingsValueRow(
                    title: "Export Notes",
                    subtitle: "Export your notes and flashcards",
                    value: "Soon",
                    token: AppVisualToken(icon: "square.and.arrow.up.fill", tint: AppTheme.blue, gradient: AppTheme.primaryGradient, softTint: AppTheme.blue.opacity(0.14))
                )
            }
        }
        .padding(18)
        .appCard(cornerRadius: 30)
    }

    private var supportCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Support")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)

            VStack(spacing: 0) {
                SettingsValueRow(
                    title: "Help Center",
                    subtitle: "Get help and find answers",
                    value: "",
                    token: AppVisualToken(icon: "questionmark.circle.fill", tint: AppTheme.purple, gradient: AppTheme.coolGradient, softTint: AppTheme.purple.opacity(0.14))
                )

                Divider().padding(.leading, 72)

                SettingsValueRow(
                    title: "Send Feedback",
                    subtitle: "Help us improve LectureMate AI",
                    value: "",
                    token: AppVisualToken(icon: "bubble.left.and.bubble.right.fill", tint: AppTheme.blue, gradient: AppTheme.primaryGradient, softTint: AppTheme.blue.opacity(0.14))
                )

                Divider().padding(.leading, 72)

                SettingsValueRow(
                    title: "Privacy Policy",
                    subtitle: "Read our privacy policy",
                    value: "",
                    token: AppVisualToken(icon: "checkmark.shield.fill", tint: AppTheme.mint, gradient: AppTheme.mintGradient, softTint: AppTheme.mint.opacity(0.14))
                )

                Divider().padding(.leading, 72)

                SettingsValueRow(
                    title: "Terms of Service",
                    subtitle: "Read our terms of service",
                    value: "",
                    token: AppVisualToken(icon: "doc.text.fill", tint: AppTheme.blue, gradient: AppTheme.primaryGradient, softTint: AppTheme.blue.opacity(0.14))
                )
            }
        }
        .padding(18)
        .appCard(cornerRadius: 30)
    }

    private var logoutCard: some View {
        Button {
            authManager.logout()
        } label: {
            HStack(spacing: 16) {
                AppIconTile(
                    token: AppVisualToken(icon: "arrow.right.square.fill", tint: AppTheme.red, gradient: LinearGradient(colors: [AppTheme.red, AppTheme.orange], startPoint: .leading, endPoint: .trailing), softTint: AppTheme.red.opacity(0.12)),
                    size: 64
                )

                VStack(alignment: .leading, spacing: 6) {
                    Text("Logout")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.red)

                    Text("Sign out of your account")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.secondaryText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .padding(18)
            .appCard(cornerRadius: 28)
        }
        .buttonStyle(.plain)
    }
}

private struct SettingsToggleRow: View {
    let title: String
    let subtitle: String
    let token: AppVisualToken
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 14) {
            AppIconTile(token: token, size: 48)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)

                Text(subtitle)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.secondaryText)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(AppTheme.blue)
        }
        .padding(.vertical, 10)
    }
}

private struct SettingsValueRow: View {
    let title: String
    let subtitle: String
    let value: String
    let token: AppVisualToken

    var body: some View {
        HStack(spacing: 14) {
            AppIconTile(token: token, size: 48)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.ink)

                Text(subtitle)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.secondaryText)
            }

            Spacer()

            HStack(spacing: 8) {
                if !value.isEmpty {
                    Text(value)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.blue)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
        .padding(.vertical, 10)
    }
}
