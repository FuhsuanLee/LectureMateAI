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

    @Published var displayName: String {
        didSet {
            UserDefaults.standard.set(displayName, forKey: "displayName")
        }
    }

    @Published var avatarURL: String? {
        didSet {
            UserDefaults.standard.set(avatarURL, forKey: "avatarURL")
        }
    }

    init() {
        // Logged-in state derives from a token present in the Keychain.
        let hasToken = KeychainHelper.read(account: KeychainHelper.githubTokenAccount) != nil
        self.isLoggedIn = hasToken
        self.username = UserDefaults.standard.string(forKey: "username") ?? ""
        self.displayName = UserDefaults.standard.string(forKey: "displayName") ?? ""
        self.avatarURL = UserDefaults.standard.string(forKey: "avatarURL")
    }

    var githubToken: String? {
        KeychainHelper.read(account: KeychainHelper.githubTokenAccount)
    }

    func completeGitHubLogin(token: String, username: String, displayName: String?, avatarURL: String?) {
        KeychainHelper.save(token, account: KeychainHelper.githubTokenAccount)
        self.username = username
        self.displayName = displayName ?? ""
        self.avatarURL = avatarURL
        self.isLoggedIn = true
    }

    func logout() {
        KeychainHelper.delete(account: KeychainHelper.githubTokenAccount)
        username = ""
        displayName = ""
        avatarURL = nil
        isLoggedIn = false
    }
}
