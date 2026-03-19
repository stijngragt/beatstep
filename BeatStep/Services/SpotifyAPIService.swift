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
        let url = URL(string: "\(baseURL)/playlists/\(playlistID)/tracks?limit=\(limit)&offset=\(offset)")!
        return try await authenticatedRequest(url: url)
    }

    func fetchCurrentUserProfile() async throws -> SpotifyUser {
        let url = URL(string: "\(baseURL)/me")!
        return try await authenticatedRequest(url: url)
    }

    // MARK: - Private

    private func authenticatedRequest<T: Decodable>(url: URL) async throws -> T {
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
            throw SpotifyError.tokenExpired
        default:
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw SpotifyError.apiError(statusCode: httpResponse.statusCode, message: message)
        }
    }
}
