//
//  LectureMateAIApp.swift
//  LectureMateAI
//
//  Created by Sherry Lee on 2026/6/3.
//

import SwiftUI
import SwiftData
import TipKit

@main
struct LectureMateAIApp: App {
    @StateObject private var authManager = AuthManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .task {
                    try? Tips.configure()
                }
        }
        .modelContainer(for: [
            Course.self,
            LectureNote.self,
            Flashcard.self,
            QuizQuestion.self
        ])
    }
}
