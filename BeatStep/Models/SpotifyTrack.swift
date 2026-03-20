import Foundation

struct Artist: Codable, Hashable {
    let name: String
}

struct Album: Codable, Hashable {
    let name: String
    let images: [SpotifyImage]?
}

struct SpotifyTrack: Codable, Identifiable, Hashable {
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

    var artistName: String {
        artists.map(\.name).joined(separator: ", ")
    }

    var durationSeconds: TimeInterval {
        TimeInterval(durationMs) / 1000.0
    }
}

struct PlaylistTrackItem: Codable {
    let item: SpotifyTrack?

    /// Backward-compatible accessor
    var track: SpotifyTrack? { item }

    enum CodingKeys: String, CodingKey {
        case item
    }
}
