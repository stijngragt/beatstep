import Foundation

final class SpotifyAPIService {
    static let shared = SpotifyAPIService()

    private let baseURL = "https://api.spotify.com/v1"

    private init() {}

    // MARK: - Public API

    func fetchPlaylists(offset: Int = 0, limit: Int = 50) async throws -> PaginatedResponse<SpotifyPlaylist> {
        let url = URL(string: "\(baseURL)/me/playlists?limit=\(limit)&offset=\(offset)")!
        return try await authenticatedRequest(url: url)
    }

    func fetchPlaylistTracks(playlistID: String, offset: Int = 0, limit: Int = 100) async throws -> PaginatedResponse<PlaylistTrackItem> {
        let url = URL(string: "\(baseURL)/playlists/\(playlistID)/items?limit=\(limit)&offset=\(offset)")!
        return try await authenticatedRequest(url: url)
    }

    func fetchCurrentUserProfile() async throws -> SpotifyUser {
        let url = URL(string: "\(baseURL)/me")!
        return try await authenticatedRequest(url: url)
    }

    // MARK: - Audio Features (BPM)

    func fetchAudioFeatures(trackID: String) async throws -> AudioFeatures {
        let url = URL(string: "\(baseURL)/audio-features/\(trackID)")!
        return try await authenticatedRequest(url: url)
    }

    func fetchBatchAudioFeatures(trackIDs: [String]) async throws -> [AudioFeatures?] {
        let ids = trackIDs.joined(separator: ",")
        let url = URL(string: "\(baseURL)/audio-features?ids=\(ids)")!
        let response: BatchAudioFeaturesResponse = try await authenticatedRequest(url: url)
        return response.audioFeatures
    }

    // MARK: - Search & Discovery

    func searchTrack(title: String, artist: String, limit: Int = 1) async throws -> [SpotifyTrack] {
        let query = "track:\(title) artist:\(artist)"
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/search?q=\(encodedQuery)&type=track&limit=\(limit)") else {
            return []
        }
        let response: SpotifySearchResponse = try await authenticatedRequest(url: url)
        return response.tracks.items
    }

    func fetchCurrentUserID() async throws -> String {
        let user = try await fetchCurrentUserProfile()
        return user.id
    }

    // MARK: - Playlist CRUD

    func createPlaylist(userID: String, name: String, description: String) async throws -> SpotifyPlaylist {
        let url = URL(string: "\(baseURL)/users/\(userID)/playlists")!
        let body = CreatePlaylistBody(name: name, description: description, isPublic: false)
        return try await authenticatedPOSTRequest(url: url, body: body)
    }

    func addTracksToPlaylist(playlistID: String, uris: [String]) async throws {
        let url = URL(string: "\(baseURL)/playlists/\(playlistID)/tracks")!
        let body = AddTracksBody(uris: uris)
        let _: SnapshotResponse = try await authenticatedPOSTRequest(url: url, body: body)
    }

    // MARK: - Internal

    func authenticatedRequest<T: Decodable>(url: URL, retried: Bool = false) async throws -> T {
        // Refresh token if needed before making request
        await SpotifyAuthService.shared.refreshTokenIfNeeded()

        guard let token = KeychainManager.shared.accessToken else {
            throw SpotifyError.notAuthenticated
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw SpotifyError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SpotifyError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            return try JSONDecoder().decode(T.self, from: data)
        case 401:
            // Try refreshing token once and retrying
            if !retried {
                let refreshed = await SpotifyAuthService.shared.refreshTokenIfNeeded()
                if refreshed {
                    return try await authenticatedRequest(url: url, retried: true)
                }
            }
            throw SpotifyError.tokenExpired
        case 403:
            let body = String(data: data, encoding: .utf8) ?? "Forbidden"
            throw SpotifyError.apiError(statusCode: 403, message: "Forbidden — \(body)")
        default:
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw SpotifyError.apiError(statusCode: httpResponse.statusCode, message: message)
        }
    }

    func authenticatedPOSTRequest<T: Decodable>(url: URL, body: Encodable) async throws -> T {
        guard let token = KeychainManager.shared.accessToken else {
            throw SpotifyError.notAuthenticated
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw SpotifyError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SpotifyError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            return try JSONDecoder().decode(T.self, from: data)
        case 401:
            throw SpotifyError.tokenExpired
        default:
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw SpotifyError.apiError(statusCode: httpResponse.statusCode, message: message)
        }
    }
}

// MARK: - Request/Response Models

struct SpotifySearchResponse: Decodable {
    let tracks: SpotifyTrackList
}

struct SpotifyTrackList: Decodable {
    let items: [SpotifyTrack]
}

private struct CreatePlaylistBody: Encodable {
    let name: String
    let description: String
    let isPublic: Bool

    enum CodingKeys: String, CodingKey {
        case name, description
        case isPublic = "public"
    }
}

private struct AddTracksBody: Encodable {
    let uris: [String]
}

struct PlaylistWithTracksResponse: Decodable {
    let tracks: PaginatedResponse<PlaylistTrackItem>
}

struct AudioFeatures: Decodable {
    let id: String
    let tempo: Double

    var bpm: Int {
        Int(tempo.rounded())
    }
}

struct BatchAudioFeaturesResponse: Decodable {
    let audioFeatures: [AudioFeatures?]

    enum CodingKeys: String, CodingKey {
        case audioFeatures = "audio_features"
    }
}

struct SnapshotResponse: Decodable {
    let snapshotId: String

    enum CodingKeys: String, CodingKey {
        case snapshotId = "snapshot_id"
    }
}
