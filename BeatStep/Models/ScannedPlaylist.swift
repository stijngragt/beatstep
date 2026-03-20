import Foundation
import SwiftData

@Model
final class ScannedPlaylist {
    @Attribute(.unique) var spotifyPlaylistID: String
    var name: String
    var isEnabled: Bool
    var totalTracks: Int
    var tracksWithBPM: Int
    var lastScanned: Date?

    init(spotifyPlaylistID: String, name: String, isEnabled: Bool = false, totalTracks: Int = 0, tracksWithBPM: Int = 0) {
        self.spotifyPlaylistID = spotifyPlaylistID
        self.name = name
        self.isEnabled = isEnabled
        self.totalTracks = totalTracks
        self.tracksWithBPM = tracksWithBPM
        self.lastScanned = nil
    }

    var coverageText: String {
        "\(tracksWithBPM) of \(totalTracks) tracks have BPM"
    }
}
