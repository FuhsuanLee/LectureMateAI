//
//  MainTabView.swift
//  LectureMateAI
//
//  Created by Sherry Lee on 2026/6/3.
//

import SwiftUI
import UIKit

private enum MainTab: Hashable {
    case dashboard
    case courses
    case flashcards
    case settings
}

struct MainTabView: View {
    @State private var selectedTab: MainTab = .dashboard

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialLight)
        appearance.backgroundColor = UIColor.white.withAlphaComponent(0.92)
        appearance.shadowColor = UIColor.black.withAlphaComponent(0.04)

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().unselectedItemTintColor = UIColor(AppTheme.secondaryText)
    }

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
        .tint(AppTheme.blue)
    }
}
