import Foundation
import SwiftData

@MainActor
final class BPMCacheService {
    static let shared = BPMCacheService()

    private var container: ModelContainer?

    private init() {}

    func setContainer(_ container: ModelContainer) {
        self.container = container
    }

    var context: ModelContext {
        container!.mainContext
    }

    func cacheFromAPI(trackID: String, name: String, artist: String, bpm: Int?) {
        let descriptor = FetchDescriptor<CachedBPM>(
            predicate: #Predicate { $0.spotifyTrackID == trackID }
        )

        if let existing = try? context.fetch(descriptor).first {
            // Manual wins over API: preserve user's explicit BPM correction
            if existing.confidenceRaw == BPMConfidence.manual.rawValue {
                existing.lookupAttempted = true
                existing.lastUpdated = Date()
            } else {
                existing.bpm = bpm
                existing.confidenceRaw = bpm != nil ? BPMConfidence.verified.rawValue : nil
                existing.sourceRaw = bpm != nil ? BPMSource.api.rawValue : nil
                existing.lookupAttempted = true
                existing.lastUpdated = Date()
            }
        } else {
            let cached = CachedBPM(spotifyTrackID: trackID, trackName: name, artistName: artist, bpm: bpm, lookupAttempted: true)
            if bpm != nil {
                cached.confidenceRaw = BPMConfidence.verified.rawValue
                cached.sourceRaw = BPMSource.api.rawValue
            }
            context.insert(cached)
        }

        try? context.save()
    }

    func cacheManual(trackID: String, name: String, artist: String, bpm: Int) {
        let descriptor = FetchDescriptor<CachedBPM>(
            predicate: #Predicate { $0.spotifyTrackID == trackID }
        )

        if let existing = try? context.fetch(descriptor).first {
            existing.bpm = bpm
            existing.confidenceRaw = BPMConfidence.manual.rawValue
            existing.sourceRaw = BPMSource.manual.rawValue
            existing.lookupAttempted = true
            existing.lastUpdated = Date()
        } else {
            let cached = CachedBPM(spotifyTrackID: trackID, trackName: name, artistName: artist, bpm: bpm, lookupAttempted: true)
            cached.confidenceRaw = BPMConfidence.manual.rawValue
            cached.sourceRaw = BPMSource.manual.rawValue
            context.insert(cached)
        }

        try? context.save()
    }

    func getBPM(forTrackID trackID: String) -> Int? {
        let descriptor = FetchDescriptor<CachedBPM>(
            predicate: #Predicate { $0.spotifyTrackID == trackID }
        )
        return try? context.fetch(descriptor).first?.bpm
    }

    func getBPMInfo(forTrackID trackID: String) -> BPMInfo {
        let descriptor = FetchDescriptor<CachedBPM>(
            predicate: #Predicate { $0.spotifyTrackID == trackID }
        )
        guard let cached = try? context.fetch(descriptor).first else {
            return .empty
        }
        return BPMInfo(bpm: cached.bpm, confidence: cached.confidence)
    }

    func clearCache(forTrackID trackID: String) {
        let descriptor = FetchDescriptor<CachedBPM>(
            predicate: #Predicate { $0.spotifyTrackID == trackID }
        )
        if let existing = try? context.fetch(descriptor).first {
            context.delete(existing)
            try? context.save()
        }
    }

    func hasLookup(forTrackID trackID: String) -> Bool {
        let descriptor = FetchDescriptor<CachedBPM>(
            predicate: #Predicate { $0.spotifyTrackID == trackID }
        )
        let count = (try? context.fetchCount(descriptor)) ?? 0
        return count > 0
    }

    func getDanceability(forTrackID trackID: String) -> Int? {
        let descriptor = FetchDescriptor<CachedBPM>(
            predicate: #Predicate { $0.spotifyTrackID == trackID }
        )
        return try? context.fetch(descriptor).first?.danceability
    }

    func cacheDanceability(trackID: String, danceability: Int) {
        let descriptor = FetchDescriptor<CachedBPM>(
            predicate: #Predicate { $0.spotifyTrackID == trackID }
        )
        if let existing = try? context.fetch(descriptor).first {
            existing.danceability = danceability
            existing.lastUpdated = Date()
            try? context.save()
        }
    }

    func coverageStats(forTrackIDs trackIDs: [String]) -> (withBPM: Int, total: Int) {
        let descriptor = FetchDescriptor<CachedBPM>(
            predicate: #Predicate<CachedBPM> { cached in
                trackIDs.contains(cached.spotifyTrackID)
            }
        )
        let results = (try? context.fetch(descriptor)) ?? []
        let withBPM = results.filter { $0.bpm != nil }.count
        return (withBPM: withBPM, total: trackIDs.count)
    }
}
