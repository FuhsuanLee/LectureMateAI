//
//  MainTabView.swift
//  LectureMateAI
//
//  Created by Sherry Lee on 2026/6/3.
//

import SwiftUI

private enum MainTab: Hashable {
    case dashboard
    case courses
    case flashcards
    case settings
}

struct MainTabView: View {
    @State private var selectedTab: MainTab = .dashboard

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView {
                selectedTab = .courses
            }
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }
                .tag(MainTab.dashboard)

            CourseListView()
                .tabItem {
                    Label("Courses", systemImage: "books.vertical.fill")
                }
                .tag(MainTab.courses)

            FlashcardLibraryView()
                .tabItem {
                    Label("Flashcards", systemImage: "rectangle.on.rectangle.fill")
                }
                .tag(MainTab.flashcards)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(MainTab.settings)
        }
    }
}
