//
//  MainTabView.swift
//  LectureMateAI
//
//  Created by Sherry Lee on 2026/6/3.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }

            CourseListView()
                .tabItem {
                    Label("Courses", systemImage: "books.vertical.fill")
                }

            FlashcardLibraryView()
                .tabItem {
                    Label("Flashcards", systemImage: "rectangle.on.rectangle.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
    }
}
