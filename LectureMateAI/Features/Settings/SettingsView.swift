//
//  SettingsView.swift
//  LectureMateAI
//
//  Created by Sherry Lee on 2026/6/3.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    Text(authManager.username.isEmpty ? "Guest" : authManager.username)

                    Button(role: .destructive) {
                        authManager.logout()
                    } label: {
                        Text("Logout")
                    }
                }

                Section("About") {
                    Text("LectureMate AI")
                    Text("AI-powered lecture notes, flashcards, quizzes, and learning dashboard.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
        }
    }
}
