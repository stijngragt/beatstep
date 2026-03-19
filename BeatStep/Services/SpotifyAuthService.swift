import Foundation
import SpotifyiOS
import SwiftUI

@Observable
class SpotifyAuthService {
    static let shared = SpotifyAuthService()

    // MARK: - Published State

    var isAuthenticated = false
    var isCheckingAuth = false
    var isPremium = false
    var currentUser: SpotifyUser?
    var authError: String?

    // MARK: - Private

    // TODO: Replace with your Spotify Client ID from developer.spotify.com
    private let clientID = "YOUR_SPOTIFY_CLIENT_ID"
    private let redirectURL = URL(string: "beatstep://spotify-callback")!

    private let additionalScopes: [String] = [
        "playlist-read-private",
        "playlist-read-collaborative",
        "user-read-private",
        "user-read-playback-state",
        "user-read-currently-playing"
    ]

    @ObservationIgnored
    private var _appRemote: SPTAppRemote?

    var appRemote: SPTAppRemote {
        if let existing = _appRemote { return existing }
        let configuration = SPTConfiguration(clientID: clientID, redirectURL: redirectURL)
        let remote = SPTAppRemote(configuration: configuration, logLevel: .debug)
        _appRemote = remote
        return remote
    }

    private init() {}

    // MARK: - Auth Flow

    func initiateAuth() {
        authError = nil

        #if targetEnvironment(simulator)
        // Spotify app cannot be installed on simulator
        authError = "Spotify auth requires a physical device"
        return
        #else
        guard UIApplication.shared.canOpenURL(URL(string: "spotify:")!) else {
            authError = "Please install Spotify to use BeatStep"
            return
        }

        appRemote.authorizeAndPlayURI(
            "",
            asRadio: false,
            additionalScopes: additionalScopes
        ) { [weak self] success in
            if !success {
                self?.authError = "Failed to open Spotify for authorization"
            }
        }
        #endif
    }

    func handleCallback(url: URL) {
        guard let parameters = appRemote.authorizationParameters(from: url) else {
            authError = "Invalid callback URL from Spotify"
            return
        }

        if let errorDescription = parameters[SPTAppRemoteErrorDescriptionKey] {
            authError = errorDescription
            return
        }

        guard let accessToken = parameters[SPTAppRemoteAccessTokenKey] else {
            authError = "No access token received from Spotify"
            return
        }

        // Store token in Keychain
        KeychainManager.shared.accessToken = accessToken
        appRemote.connectionParameters.accessToken = accessToken

        // Check premium status
        isCheckingAuth = true
        Task {
            await checkPremiumStatus()
        }
    }

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
        guard let token = KeychainManager.shared.accessToken else {
            isAuthenticated = false
            return
        }

        isCheckingAuth = true
        Task {
            do {
                let user = try await fetchUserProfile(token: token)
                if user.isPremium {
                    isPremium = true
                    isAuthenticated = true
                    currentUser = user
                } else {
                    disconnect()
                    authError = "BeatStep requires Spotify Premium"
                }
            } catch {
                // Token invalid or expired
                disconnect()
            }
            isCheckingAuth = false
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
}
