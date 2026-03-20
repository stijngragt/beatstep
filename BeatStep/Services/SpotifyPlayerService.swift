import Foundation
import UIKit

@Observable
class SpotifyPlayerService {
    static let shared = SpotifyPlayerService()

    // MARK: - Observable State

    var currentTrack: SpotifyTrack?
    var isPaused = true
    var isPolling = false

    // MARK: - Private

    private let baseURL = "https://api.spotify.com/v1"
    private var pollTask: Task<Void, Never>?

    private init() {}

    // MARK: - Playback Control

    func connect() {
        startPolling()
    }

    func disconnect() {
        stopPolling()
    }

    func play(uri: String, contextURI: String? = nil) {
        Task {
            // Try Web API first
            let played = await playViaAPI(uri: uri, contextURI: contextURI)
            if !played {
                // Fallback: open in Spotify app
                if let url = URL(string: uri) {
                    await MainActor.run {
                        UIApplication.shared.open(url)
                    }
                }
            }
            // Fetch state after a short delay
            try? await Task.sleep(for: .milliseconds(500))
            await fetchCurrentPlayback()
        }
    }

    func togglePlayPause() {
        if isPaused {
            resume()
        } else {
            pause()
        }
    }

    func skipNext() {
        Task {
            await performPlayerAction(endpoint: "/me/player/next", method: "POST")
            try? await Task.sleep(for: .milliseconds(300))
            await fetchCurrentPlayback()
        }
    }

    // MARK: - Web API Player

    func resume() {
        Task {
            await performPlayerAction(endpoint: "/me/player/play", method: "PUT")
            isPaused = false
        }
    }

    func pause() {
        Task {
            await performPlayerAction(endpoint: "/me/player/pause", method: "PUT")
            isPaused = true
        }
    }

    private func playViaAPI(uri: String, contextURI: String?) async -> Bool {
        guard let token = KeychainManager.shared.accessToken,
              let url = URL(string: "\(baseURL)/me/player/play") else { return false }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Build request body
        var body: [String: Any] = ["uris": [uri]]
        if let contextURI {
            body = ["context_uri": contextURI, "offset": ["uri": uri]]
        }
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        guard let (_, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse else { return false }

        return (200...299).contains(http.statusCode)
    }

    private func performPlayerAction(endpoint: String, method: String) async {
        guard let token = KeychainManager.shared.accessToken,
              let url = URL(string: "\(baseURL)\(endpoint)") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        _ = try? await URLSession.shared.data(for: request)
    }

    // MARK: - Polling

    func startPolling() {
        guard !isPolling else { return }
        isPolling = true

        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.fetchCurrentPlayback()
                try? await Task.sleep(for: .seconds(3))
            }
        }
    }

    func stopPolling() {
        isPolling = false
        pollTask?.cancel()
        pollTask = nil
    }

    @MainActor
    func fetchCurrentPlayback() async {
        guard let token = KeychainManager.shared.accessToken,
              let url = URL(string: "\(baseURL)/me/player/currently-playing") else { return }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse else { return }

        if http.statusCode == 204 {
            // Nothing playing
            currentTrack = nil
            isPaused = true
            return
        }

        guard http.statusCode == 200 else { return }

        do {
            let playback = try JSONDecoder().decode(CurrentlyPlayingResponse.self, from: data)
            isPaused = !playback.isPlaying

            if let item = playback.item {
                currentTrack = SpotifyTrack(
                    id: item.id,
                    name: item.name,
                    uri: item.uri,
                    durationMs: item.durationMs,
                    artists: item.artists,
                    album: item.album
                )
            }
        } catch {
            debugPrint("Player: Failed to decode playback: \(error)")
        }
    }
}

// MARK: - Response Models

private struct CurrentlyPlayingResponse: Decodable {
    let isPlaying: Bool
    let item: CurrentlyPlayingItem?

    enum CodingKeys: String, CodingKey {
        case isPlaying = "is_playing"
        case item
    }
}

private struct CurrentlyPlayingItem: Decodable {
    let id: String
    let name: String
    let uri: String
    let durationMs: Int
    let artists: [Artist]
    let album: Album

    enum CodingKeys: String, CodingKey {
        case id, name, uri
        case durationMs = "duration_ms"
        case artists, album
    }
}
