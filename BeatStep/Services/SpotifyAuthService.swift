import Foundation
import AuthenticationServices
import SpotifyiOS
import SwiftUI
import CryptoKit

@Observable
class SpotifyAuthService: NSObject {
    static let shared = SpotifyAuthService()

    // MARK: - Published State

    var isAuthenticated = false
    var isCheckingAuth = false
    var isPremium = false
    var currentUser: SpotifyUser?
    var authError: String?

    // MARK: - Private

    let clientID = Secrets.spotifyClientID
    let redirectURL = URL(string: "beatstep://spotify-callback")!

    private let scopes = [
        "playlist-read-private",
        "playlist-read-collaborative",
        "user-read-private",
        "user-read-playback-state",
        "user-read-currently-playing",
        "app-remote-control",
        "streaming"
    ].joined(separator: " ")

    private let tokenURL = URL(string: "https://accounts.spotify.com/api/token")!
    private var codeVerifier: String?

    @ObservationIgnored
    private var authSession: ASWebAuthenticationSession?

    @ObservationIgnored
    private var _appRemote: SPTAppRemote?

    var appRemote: SPTAppRemote {
        if let existing = _appRemote { return existing }
        let configuration = SPTConfiguration(clientID: clientID, redirectURL: redirectURL)
        let remote = SPTAppRemote(configuration: configuration, logLevel: .debug)
        _appRemote = remote
        return remote
    }

    private override init() {
        super.init()
    }

    // MARK: - PKCE Auth Flow

    func initiateAuth() {
        authError = nil

        // Clear any old tokens so we start fresh
        KeychainManager.shared.clearAll()
        isAuthenticated = false

        // Generate PKCE code verifier and challenge
        let verifier = generateCodeVerifier()
        codeVerifier = verifier
        let challenge = generateCodeChallenge(from: verifier)

        var components = URLComponents(string: "https://accounts.spotify.com/authorize")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri", value: redirectURL.absoluteString),
            URLQueryItem(name: "scope", value: scopes),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "code_challenge", value: challenge)
        ]

        guard let authURL = components.url else {
            authError = "Failed to build authorization URL"
            return
        }

        authSession = ASWebAuthenticationSession(
            url: authURL,
            callbackURLScheme: "beatstep"
        ) { [weak self] callbackURL, error in
            guard let self else { return }

            if let error {
                if (error as NSError).code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                    return
                }
                Task { @MainActor in
                    self.authError = error.localizedDescription
                }
                return
            }

            guard let callbackURL,
                  let code = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?
                    .queryItems?.first(where: { $0.name == "code" })?.value else {
                Task { @MainActor in
                    self.authError = "No authorization code received"
                }
                return
            }
            Task {
                await self.exchangeCodeForToken(code: code)
            }
        }

        authSession?.presentationContextProvider = self
        authSession?.prefersEphemeralWebBrowserSession = false
        authSession?.start()
    }

    // MARK: - Token Exchange

    @MainActor
    private func exchangeCodeForToken(code: String) async {
        guard let verifier = codeVerifier else {
            authError = "Missing code verifier"
            return
        }

        isCheckingAuth = true
        defer { isCheckingAuth = false }

        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = [
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": redirectURL.absoluteString,
            "client_id": clientID,
            "code_verifier": verifier
        ]
        request.httpBody = body.map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                authError = "Token exchange: invalid response"
                return
            }

            guard httpResponse.statusCode == 200 else {
                let message = String(data: data, encoding: .utf8) ?? "Token exchange failed"
                authError = message
                return
            }

            let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)

            // Store tokens
            KeychainManager.shared.accessToken = tokenResponse.accessToken
            KeychainManager.shared.refreshToken = tokenResponse.refreshToken
            KeychainManager.shared.tokenExpirationDate = Date().addingTimeInterval(TimeInterval(tokenResponse.expiresIn))

            // Connect app remote with the new token
            appRemote.connectionParameters.accessToken = tokenResponse.accessToken

            // Verify premium
            await checkPremiumStatus()
        } catch {
            authError = "Token exchange failed: \(error.localizedDescription)"
        }

        codeVerifier = nil
    }

    // MARK: - Token Refresh

    @MainActor
    func refreshTokenIfNeeded() async -> Bool {
        guard let expirationDate = KeychainManager.shared.tokenExpirationDate else {
            return false
        }

        // Refresh if token expires within 5 minutes
        guard expirationDate.timeIntervalSinceNow < 300 else {
            return true // Token still valid
        }

        guard let refreshToken = KeychainManager.shared.refreshToken else {
            return false
        }

        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = [
            "grant_type": "refresh_token",
            "refresh_token": refreshToken,
            "client_id": clientID
        ]
        request.httpBody = body.map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return false
            }

            let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)

            KeychainManager.shared.accessToken = tokenResponse.accessToken
            if let newRefreshToken = tokenResponse.refreshToken {
                KeychainManager.shared.refreshToken = newRefreshToken
            }
            KeychainManager.shared.tokenExpirationDate = Date().addingTimeInterval(TimeInterval(tokenResponse.expiresIn))

            appRemote.connectionParameters.accessToken = tokenResponse.accessToken
            return true
        } catch {
            return false
        }
    }

    // MARK: - Premium Check

    @MainActor
    func checkPremiumStatus() async {
        isCheckingAuth = true
        defer { isCheckingAuth = false }

        guard let token = KeychainManager.shared.accessToken else {
            authError = "No access token available"
            return
        }

        do {
            let user = try await fetchUserProfile(token: token)

            if user.isPremium {
                isPremium = true
                isAuthenticated = true
                currentUser = user
                authError = nil
            } else {
                isPremium = false
                isAuthenticated = false
                authError = "BeatStep requires Spotify Premium"
                KeychainManager.shared.clearAll()
            }
        } catch {
            authError = "Failed to verify account: \(error.localizedDescription)"
            isAuthenticated = false
            KeychainManager.shared.clearAll()
        }
    }

    func disconnect() {
        KeychainManager.shared.clearAll()
        isAuthenticated = false
        isPremium = false
        currentUser = nil
        authError = nil
    }

    @MainActor
    func checkExistingAuth() {
        guard KeychainManager.shared.accessToken != nil else {
            isAuthenticated = false
            return
        }

        isCheckingAuth = true
        Task {
            // Try to refresh if needed, but don't disconnect on failure —
            // the access token may still be valid even if refresh fails
            _ = await refreshTokenIfNeeded()

            await checkPremiumStatus()
        }
    }

    // MARK: - API

    private func fetchUserProfile(token: String) async throws -> SpotifyUser {
        let url = URL(string: "https://api.spotify.com/v1/me")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SpotifyError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            return try JSONDecoder().decode(SpotifyUser.self, from: data)
        case 401:
            throw SpotifyError.tokenExpired
        default:
            throw SpotifyError.apiError(
                statusCode: httpResponse.statusCode,
                message: String(data: data, encoding: .utf8) ?? "Unknown error"
            )
        }
    }

    // MARK: - PKCE Helpers

    private func generateCodeVerifier() -> String {
        var buffer = [UInt8](repeating: 0, count: 32)
        _ = SecRandomCopyBytes(kSecRandomDefault, buffer.count, &buffer)
        return Data(buffer).base64URLEncodedString()
    }

    private func generateCodeChallenge(from verifier: String) -> String {
        let data = Data(verifier.utf8)
        let hash = SHA256.hash(data: data)
        return Data(hash).base64URLEncodedString()
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding

extension SpotifyAuthService: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            return ASPresentationAnchor()
        }
        return window
    }
}

// MARK: - Token Response

private struct TokenResponse: Decodable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int
    let refreshToken: String?
    let scope: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
        case scope
    }
}

// MARK: - Base64URL

extension Data {
    func base64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
