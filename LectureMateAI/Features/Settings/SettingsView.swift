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
    @State private var showingLogoutConfirmation = false

    var body: some View {
        NavigationStack {
            Form {
                profileSection
                preferencesSection
                supportSection
                logoutSection
            }
            .navigationTitle("Settings")
            .confirmationDialog(
                "Are you sure you want to log out?",
                isPresented: $showingLogoutConfirmation,
                titleVisibility: .visible
            ) {
                Button("Log Out", role: .destructive) {
                    authManager.logout()
                }
            }
        }
    }

    private var profileSection: some View {
        Section {
            HStack(spacing: 12) {
                AppAvatarBadge(name: authManager.displayName, size: 52)

                VStack(alignment: .leading, spacing: 2) {
                    Text(authManager.displayName)
                        .font(.headline)

                    Text(authManager.username.isEmpty ? "guest@lecturemate.ai" : authManager.username)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var preferencesSection: some View {
        Section("Preferences") {
            Toggle(isOn: $notificationsEnabled) {
                SettingsRowLabel(icon: "bell.fill", tint: AppTheme.flashcards, title: "Notifications")
            }

            Toggle(isOn: $studyReminderEnabled) {
                SettingsRowLabel(icon: "calendar.badge.clock", tint: .green, title: "Study Reminder")
            }

            LabeledContent {
                Text("System")
            } label: {
                SettingsRowLabel(icon: "paintpalette.fill", tint: AppTheme.quiz, title: "Appearance")
            }

            LabeledContent {
                Text("Soon")
            } label: {
                SettingsRowLabel(icon: "square.and.arrow.up.fill", tint: .accentColor, title: "Export Notes")
            }
        }
    }

    private var supportSection: some View {
        Section("Support") {
            SettingsRowLabel(icon: "questionmark.circle.fill", tint: AppTheme.flashcards, title: "Help Center")
            SettingsRowLabel(icon: "bubble.left.and.bubble.right.fill", tint: .accentColor, title: "Send Feedback")
            SettingsRowLabel(icon: "checkmark.shield.fill", tint: .green, title: "Privacy Policy")
            SettingsRowLabel(icon: "doc.text.fill", tint: .accentColor, title: "Terms of Service")
        }
    }

    private var logoutSection: some View {
        Section {
            Button("Log Out", role: .destructive) {
                showingLogoutConfirmation = true
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// Shared icon-badge + title row label used by the preference and support rows.
private struct SettingsRowLabel: View {
    let icon: String
    let tint: Color
    let title: String

    var body: some View {
        HStack(spacing: 12) {
            AppIconBadge(icon: icon, tint: tint, size: 30)

            Text(title)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthManager())
}
