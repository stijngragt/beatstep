import Foundation

struct PlaylistOwner: Codable, Hashable {
    let displayName: String?

    enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
    }
}

struct TracksRef: Codable, Hashable {
    let total: Int
}

struct SpotifyPlaylist: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let description: String?
    let images: [SpotifyImage]?
    let tracks: TracksRef
    let owner: PlaylistOwner?
}
