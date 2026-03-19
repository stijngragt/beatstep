import Foundation

enum SpotifyError: LocalizedError {
    case notAuthenticated
    case tokenExpired
    case invalidResponse
    case premiumRequired
    case spotifyNotInstalled
    case networkError(Error)
    case apiError(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not authenticated with Spotify"
        case .tokenExpired:
            return "Spotify session expired. Please sign in again."
        case .invalidResponse:
            return "Invalid response from Spotify"
        case .premiumRequired:
            return "BeatStep requires Spotify Premium"
        case .spotifyNotInstalled:
            return "Please install Spotify to use BeatStep"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .apiError(let statusCode, let message):
            return "Spotify API error (\(statusCode)): \(message)"
        }
    }
}
