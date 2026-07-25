import Foundation
import AuthenticationServices
import UIKit

/// OAuth tokens persisted (in the Keychain) between launches.
struct OAuthTokens: Codable {
    var accessToken: String
    var refreshToken: String?
    var expiresAt: Date

    /// Treated as expired one minute early to avoid using a token mid-flight.
    var isExpired: Bool { Date() >= expiresAt.addingTimeInterval(-60) }
}

/// Dependency-free Google OAuth 2.0 (authorization code + PKCE) for installed apps,
/// using `ASWebAuthenticationSession` for consent and `URLSession` for the token
/// endpoints. Tokens are stored in the Keychain.
@MainActor
final class GoogleOAuthClient: NSObject {
    private let config: GoogleDriveConfig
    private let session: URLSession
    private let keychainService = "com.ichigo.app.googledrive"
    private let keychainAccount = "oauth-tokens"
    private var webSession: ASWebAuthenticationSession?

    init(config: GoogleDriveConfig, session: URLSession = .shared) {
        self.config = config
        self.session = session
        super.init()
    }

    var isSignedIn: Bool { loadTokens() != nil }

    func signOut() {
        KeychainStore.delete(service: keychainService, account: keychainAccount)
    }

    func signIn() async throws {
        let verifier = PKCE.randomString()
        let challenge = PKCE.challenge(for: verifier)
        let state = PKCE.randomString()

        var components = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: config.clientID),
            URLQueryItem(name: "redirect_uri", value: config.redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: GoogleDriveConfig.scope),
            URLQueryItem(name: "code_challenge", value: challenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "access_type", value: "offline"),
            URLQueryItem(name: "prompt", value: "consent")
        ]
        guard let authURL = components?.url else {
            throw DriveBackupError.authFailed("URL otorisasi tidak valid.")
        }

        let callback = try await authenticate(url: authURL, scheme: config.redirectScheme)
        let items = URLComponents(url: callback, resolvingAgainstBaseURL: false)?.queryItems ?? []
        guard let code = items.first(where: { $0.name == "code" })?.value,
              items.first(where: { $0.name == "state" })?.value == state else {
            throw DriveBackupError.authFailed("Respons callback tidak valid.")
        }

        let tokens = try await exchange(code: code, verifier: verifier)
        saveTokens(tokens)
    }

    /// Reads the signed-in account's email address (requires the `email` scope).
    /// Returns `nil` rather than throwing: a missing address must not fail a backup.
    func fetchAccountEmail() async -> String? {
        guard let token = try? await validAccessToken(),
              let url = URL(string: "https://openidconnect.googleapis.com/v1/userinfo") else {
            return nil
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        guard let (data, response) = try? await session.data(for: request),
              let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode),
              let info = try? JSONDecoder().decode(UserInfo.self, from: data) else {
            return nil
        }
        return info.email
    }

    private struct UserInfo: Decodable { let email: String? }

    /// Returns a currently-valid access token, refreshing it first if needed.
    func validAccessToken() async throws -> String {
        guard let tokens = loadTokens() else { throw DriveBackupError.notSignedIn }
        if !tokens.isExpired { return tokens.accessToken }
        guard let refreshToken = tokens.refreshToken else { throw DriveBackupError.notSignedIn }
        let refreshed = try await refresh(refreshToken: refreshToken)
        saveTokens(refreshed)
        return refreshed.accessToken
    }

    // MARK: - Web auth

    private func authenticate(url: URL, scheme: String) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let webSession = ASWebAuthenticationSession(url: url, callbackURLScheme: scheme) { callback, error in
                if let error {
                    let nsError = error as NSError
                    if nsError.domain == ASWebAuthenticationSessionErrorDomain,
                       nsError.code == ASWebAuthenticationSessionError.Code.canceledLogin.rawValue {
                        continuation.resume(throwing: DriveBackupError.authCancelled)
                    } else {
                        continuation.resume(throwing: DriveBackupError.authFailed(error.localizedDescription))
                    }
                    return
                }
                guard let callback else {
                    continuation.resume(throwing: DriveBackupError.authFailed("Tidak ada callback."))
                    return
                }
                continuation.resume(returning: callback)
            }
            webSession.presentationContextProvider = self
            webSession.prefersEphemeralWebBrowserSession = false
            self.webSession = webSession
            if !webSession.start() {
                continuation.resume(throwing: DriveBackupError.authFailed("Tidak bisa memulai sesi login."))
            }
        }
    }

    // MARK: - Token endpoints

    private func exchange(code: String, verifier: String) async throws -> OAuthTokens {
        try await tokenRequest(parameters: [
            "client_id": config.clientID,
            "code": code,
            "code_verifier": verifier,
            "grant_type": "authorization_code",
            "redirect_uri": config.redirectURI
        ])
    }

    private func refresh(refreshToken: String) async throws -> OAuthTokens {
        try await tokenRequest(parameters: [
            "client_id": config.clientID,
            "refresh_token": refreshToken,
            "grant_type": "refresh_token"
        ], fallbackRefreshToken: refreshToken)
    }

    private func tokenRequest(parameters: [String: String], fallbackRefreshToken: String? = nil) async throws -> OAuthTokens {
        guard let url = URL(string: "https://oauth2.googleapis.com/token") else {
            throw DriveBackupError.authFailed("URL token tidak valid.")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = formURLEncoded(parameters).data(using: .utf8)

        let (data, response) = try await dataTask(request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw DriveBackupError.authFailed(oauthErrorMessage(data))
        }
        let decoded = try JSONDecoder().decode(TokenResponse.self, from: data)
        return OAuthTokens(
            accessToken: decoded.access_token,
            refreshToken: decoded.refresh_token ?? fallbackRefreshToken,
            expiresAt: Date().addingTimeInterval(TimeInterval(decoded.expires_in))
        )
    }

    private struct TokenResponse: Decodable {
        let access_token: String
        let expires_in: Int
        let refresh_token: String?
    }

    private func dataTask(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch {
            throw DriveBackupError.network(error.localizedDescription)
        }
    }

    // MARK: - Keychain

    private func loadTokens() -> OAuthTokens? {
        guard let data = KeychainStore.load(service: keychainService, account: keychainAccount) else { return nil }
        return try? JSONDecoder().decode(OAuthTokens.self, from: data)
    }

    private func saveTokens(_ tokens: OAuthTokens) {
        guard let data = try? JSONEncoder().encode(tokens) else { return }
        KeychainStore.save(data, service: keychainService, account: keychainAccount)
    }

    // MARK: - Helpers

    private func formURLEncoded(_ parameters: [String: String]) -> String {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        return parameters
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: allowed) ?? $0.value)" }
            .joined(separator: "&")
    }

    private func oauthErrorMessage(_ data: Data) -> String {
        if let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let description = object["error_description"] as? String {
            return description
        }
        return String(data: data, encoding: .utf8) ?? "OAuth error"
    }
}

extension GoogleOAuthClient: ASWebAuthenticationPresentationContextProviding {
    nonisolated func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            let windows = scenes.flatMap(\.windows)
            if let keyWindow = windows.first(where: \.isKeyWindow) { return keyWindow }
            if let anyWindow = windows.first { return anyWindow }
            if let scene = scenes.first { return UIWindow(windowScene: scene) }
            return UIWindow(frame: .zero)
        }
    }
}
