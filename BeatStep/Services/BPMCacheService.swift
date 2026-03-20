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

    func cache(trackID: String, name: String, artist: String, bpm: Int?) {
        let descriptor = FetchDescriptor<CachedBPM>(
            predicate: #Predicate { $0.spotifyTrackID == trackID }
        )

        if let existing = try? context.fetch(descriptor).first {
            existing.bpm = bpm
            existing.lookupAttempted = true
            existing.lastUpdated = Date()
        } else {
            let cached = CachedBPM(spotifyTrackID: trackID, trackName: name, artistName: artist, bpm: bpm, lookupAttempted: true)
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

    func hasLookup(forTrackID trackID: String) -> Bool {
        let descriptor = FetchDescriptor<CachedBPM>(
            predicate: #Predicate { $0.spotifyTrackID == trackID }
        )
        let count = (try? context.fetchCount(descriptor)) ?? 0
        return count > 0
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
