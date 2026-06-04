//
//  ContentView.swift
//  LectureMateAI
//
//  Created by Sherry Lee on 2026/6/3.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        if authManager.isLoggedIn {
            MainTabView()
        } else {
            LoginView()
        }
    }
}

#Preview {
    ContentViewPreview()
}

private struct ContentViewPreview: View {
    @StateObject private var authManager: AuthManager = {
        let manager = AuthManager()
        manager.login(email: "test@test.com", password: "123456")
        return manager
    }()

    var body: some View {
        ContentView()
            .environmentObject(authManager)
            .modelContainer(for: [
                Course.self,
                LectureNote.self,
                Flashcard.self,
                QuizQuestion.self
            ], inMemory: true)
    }
}
