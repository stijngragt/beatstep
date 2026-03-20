import Foundation
import SwiftData

@Model
final class CachedBPM {
    @Attribute(.unique) var spotifyTrackID: String
    var trackName: String
    var artistName: String
    var bpm: Int?
    var lookupAttempted: Bool
    var lastUpdated: Date

    init(spotifyTrackID: String, trackName: String, artistName: String, bpm: Int? = nil, lookupAttempted: Bool = false) {
        self.spotifyTrackID = spotifyTrackID
        self.trackName = trackName
        self.artistName = artistName
        self.bpm = bpm
        self.lookupAttempted = lookupAttempted
        self.lastUpdated = Date()
    }
}
