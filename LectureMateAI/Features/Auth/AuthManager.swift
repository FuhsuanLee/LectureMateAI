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

    func login(email: String, password: String) {
        username = email
        isLoggedIn = true
    }

    func logout() {
        username = ""
        isLoggedIn = false
    }
}
