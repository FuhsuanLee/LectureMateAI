//
//  GitHubOAuthService.swift
//  LectureMateAI
//

import Foundation
import AuthenticationServices

enum GitHubOAuthError: LocalizedError {
    case notConfigured
    case canceled
    case invalidCallback
    case stateMismatch
    case tokenExchangeFailed(String)
    case profileFetchFailed(String)
    case network(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "GitHub sign-in is not configured. Add a client ID and secret in GitHubConfig."
        case .canceled:
            return "Sign-in was canceled."
        case .invalidCallback:
            return "GitHub returned an invalid response."
        case .stateMismatch:
            return "Sign-in failed a security check. Please try again."
        case .tokenExchangeFailed(let message):
            return "Could not complete sign-in: \(message)"
        case .profileFetchFailed(let message):
            return "Could not load your GitHub profile: \(message)"
        case .network(let message):
            return message
        }
    }
}

@MainActor
final class GitHubOAuthService: NSObject {
    private let session: URLSession
    private var authSession: ASWebAuthenticationSession?

    init(session: URLSession = .shared) {
        self.session = session
        super.init()
    }

    struct Profile {
        let token: String
        let username: String
        let displayName: String?
        let avatarURL: String?
    }

    func signIn() async throws -> Profile {
        guard !GitHubConfig.clientId.isEmpty, !GitHubConfig.clientSecret.isEmpty else {
            throw GitHubOAuthError.notConfigured
        }

        let state = UUID().uuidString
        let code = try await authorize(state: state)
        let token = try await exchangeToken(code: code)
        let user = try await fetchUser(token: token)
        return Profile(token: token, username: user.login, displayName: user.name, avatarURL: user.avatarURL)
    }

    // MARK: - Authorize (browser)

    private func authorize(state: String) async throws -> String {
        var components = URLComponents(string: GitHubConfig.authorizeURL)!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: GitHubConfig.clientId),
            URLQueryItem(name: "redirect_uri", value: GitHubConfig.redirectURI),
            URLQueryItem(name: "scope", value: GitHubConfig.scope),
            URLQueryItem(name: "state", value: state)
        ]

        guard let url = components.url else {
            throw GitHubOAuthError.invalidCallback
        }

        let callbackURL: URL = try await withCheckedThrowingContinuation { continuation in
            let authSession = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: GitHubConfig.callbackScheme
            ) { callbackURL, error in
                if let error = error {
                    let nsError = error as NSError
                    if nsError.domain == ASWebAuthenticationSessionError.errorDomain,
                       nsError.code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                        continuation.resume(throwing: GitHubOAuthError.canceled)
                    } else {
                        continuation.resume(throwing: GitHubOAuthError.network(error.localizedDescription))
                    }
                    return
                }
                guard let callbackURL = callbackURL else {
                    continuation.resume(throwing: GitHubOAuthError.invalidCallback)
                    return
                }
                continuation.resume(returning: callbackURL)
            }

            authSession.presentationContextProvider = self
            authSession.prefersEphemeralWebBrowserSession = true
            self.authSession = authSession

            if !authSession.start() {
                continuation.resume(throwing: GitHubOAuthError.network("Could not open the GitHub sign-in page."))
            }
        }

        let items = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?.queryItems
        guard let returnedState = items?.first(where: { $0.name == "state" })?.value,
              returnedState == state else {
            throw GitHubOAuthError.stateMismatch
        }
        guard let code = items?.first(where: { $0.name == "code" })?.value, !code.isEmpty else {
            throw GitHubOAuthError.invalidCallback
        }
        return code
    }

    // MARK: - Token exchange

    private struct TokenResponse: Decodable {
        let accessToken: String?
        let error: String?
        let errorDescription: String?

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case error
            case errorDescription = "error_description"
        }
    }

    private func exchangeToken(code: String) async throws -> String {
        var request = URLRequest(url: URL(string: GitHubConfig.tokenURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        var body = URLComponents()
        body.queryItems = [
            URLQueryItem(name: "client_id", value: GitHubConfig.clientId),
            URLQueryItem(name: "client_secret", value: GitHubConfig.clientSecret),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "redirect_uri", value: GitHubConfig.redirectURI)
        ]
        request.httpBody = body.query?.data(using: .utf8)

        let (data, response) = try await dataForRequest(request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw GitHubOAuthError.tokenExchangeFailed("Unexpected server response.")
        }

        let decoded = try JSONDecoder().decode(TokenResponse.self, from: data)
        if let token = decoded.accessToken, !token.isEmpty {
            return token
        }
        let message = decoded.errorDescription ?? decoded.error ?? "No access token returned."
        throw GitHubOAuthError.tokenExchangeFailed(message)
    }

    // MARK: - Fetch profile

    private struct UserResponse: Decodable {
        let login: String
        let name: String?
        let avatarURL: String?

        enum CodingKeys: String, CodingKey {
            case login
            case name
            case avatarURL = "avatar_url"
        }
    }

    private func fetchUser(token: String) async throws -> UserResponse {
        var request = URLRequest(url: URL(string: GitHubConfig.userURL)!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

        let (data, response) = try await dataForRequest(request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw GitHubOAuthError.profileFetchFailed("Unexpected server response.")
        }

        do {
            return try JSONDecoder().decode(UserResponse.self, from: data)
        } catch {
            throw GitHubOAuthError.profileFetchFailed(error.localizedDescription)
        }
    }

    private func dataForRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch {
            throw GitHubOAuthError.network(error.localizedDescription)
        }
    }
}

extension GitHubOAuthService: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive } ??
            UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first

        return scene?.keyWindow ?? ASPresentationAnchor()
    }
}
