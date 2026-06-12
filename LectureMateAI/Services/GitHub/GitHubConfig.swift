//
//  GitHubConfig.swift
//  LectureMateAI
//

import Foundation

enum GitHubConfig {
    // Credentials are read at runtime from a bundled, gitignored Secrets.plist
    // (see Secrets.example.plist). Never hardcode a real secret.
    static let clientId = Secrets.string("GitHubClientID")
    static let clientSecret = Secrets.string("GitHubClientSecret")
    static let scope = "read:user"
    static let callbackScheme = "lecturemate"
    static let redirectURI = "lecturemate://callback"

    static let authorizeURL = "https://github.com/login/oauth/authorize"
    static let tokenURL = "https://github.com/login/oauth/access_token"
    static let userURL = "https://api.github.com/user"
}
