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
    var danceability: Int?
    var confidenceRaw: String?
    var sourceRaw: String?

    // MARK: - Computed Enum Accessors

    var confidence: BPMConfidence? {
        get {
            if let raw = confidenceRaw {
                return BPMConfidence(rawValue: raw)
            }
            // Lazy backfill: existing records with bpm but no confidenceRaw
            return bpm != nil ? .verified : nil
        }
        set {
            confidenceRaw = newValue?.rawValue
        }
    }

    var source: BPMSource? {
        get {
            if let raw = sourceRaw {
                return BPMSource(rawValue: raw)
            }
            // Lazy backfill: existing records with bpm but no sourceRaw
            return bpm != nil ? .api : nil
        }
        set {
            sourceRaw = newValue?.rawValue
        }
    }

    // MARK: - Convenience Accessors

    var isManual: Bool { confidence == .manual }
    var isVerified: Bool { confidence == .verified }

    init(spotifyTrackID: String, trackName: String, artistName: String, bpm: Int? = nil, lookupAttempted: Bool = false, danceability: Int? = nil) {
        self.spotifyTrackID = spotifyTrackID
        self.trackName = trackName
        self.artistName = artistName
        self.bpm = bpm
        self.lookupAttempted = lookupAttempted
        self.lastUpdated = Date()
        self.danceability = danceability
    }
}
