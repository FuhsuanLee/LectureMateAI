//
//  AuthManager.swift
//  LectureMateAI
//
//  Created by Sherry Lee on 2026/6/3.
//

import Foundation
import Combine

class AuthManager: ObservableObject {
    @Published var isLoggedIn: Bool {
        didSet {
            UserDefaults.standard.set(isLoggedIn, forKey: "isLoggedIn")
        }
    }

    @Published var username: String {
        didSet {
            UserDefaults.standard.set(username, forKey: "username")
        }
    }

    init() {
        self.isLoggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")
        self.username = UserDefaults.standard.string(forKey: "username") ?? ""
    }

    // Reader-friendly name derived from the signed-in email, shared by every
    // view that shows the user's identity.
    var displayName: String {
        let rawValue = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !rawValue.isEmpty else { return "Student" }

        let candidate = rawValue.split(separator: "@").first.map(String.init) ?? rawValue
        return candidate
            .replacingOccurrences(of: ".", with: " ")
            .split(separator: " ")
            .map { $0.capitalized }
            .joined(separator: " ")
    }

    func login(email: String, password: String) {
        username = email
        isLoggedIn = true
    }

    func logout() {
        username = ""
        isLoggedIn = false
    }
}
