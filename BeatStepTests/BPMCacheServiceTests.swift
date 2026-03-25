import XCTest
import SwiftData
@testable import BeatStep

@MainActor
final class BPMCacheServiceTests: XCTestCase {

    private var container: ModelContainer!
    private var service: BPMCacheService!

    override func setUp() async throws {
        try await super.setUp()
        let schema = Schema([CachedBPM.self, ScannedPlaylist.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        service = BPMCacheService.shared
        service.setContainer(container)
    }

    override func tearDown() async throws {
        container = nil
        try await super.tearDown()
    }

    // MARK: - Cache Insert and Retrieve

    func testCacheInsertAndRetrieve() {
        service.cacheFromAPI(trackID: "track_1", name: "Run Boy Run", artist: "Woodkid", bpm: 172)
        let bpm = service.getBPM(forTrackID: "track_1")
        XCTAssertEqual(bpm, 172)
    }

    func testCacheReturnsNilForUnknown() {
        let bpm = service.getBPM(forTrackID: "nonexistent")
        XCTAssertNil(bpm)
    }

    // MARK: - Cache Update

    func testCacheUpdateExistingTrack() {
        service.cacheFromAPI(trackID: "track_1", name: "Run Boy Run", artist: "Woodkid", bpm: 170)
        service.cacheFromAPI(trackID: "track_1", name: "Run Boy Run", artist: "Woodkid", bpm: 172)
        let bpm = service.getBPM(forTrackID: "track_1")
        XCTAssertEqual(bpm, 172)
    }

    // MARK: - HasLookup

    func testHasLookupReturnsFalseForUnknown() {
        XCTAssertFalse(service.hasLookup(forTrackID: "unknown_track"))
    }

    func testHasLookupReturnsTrueForCached() {
        service.cacheFromAPI(trackID: "track_1", name: "Song", artist: "Artist", bpm: 120)
        XCTAssertTrue(service.hasLookup(forTrackID: "track_1"))
    }

    // MARK: - Nil BPM with lookupAttempted

    func testCacheNilBPMSetsLookupAttempted() {
        service.cacheFromAPI(trackID: "track_1", name: "Unknown Song", artist: "Unknown", bpm: nil)
        XCTAssertTrue(service.hasLookup(forTrackID: "track_1"))
        XCTAssertNil(service.getBPM(forTrackID: "track_1"))

        // Verify lookupAttempted is true
        let descriptor = FetchDescriptor<CachedBPM>(
            predicate: #Predicate { $0.spotifyTrackID == "track_1" }
        )
        let cached = try? container.mainContext.fetch(descriptor).first
        XCTAssertEqual(cached?.lookupAttempted, true)
    }

    // MARK: - Coverage Stats

    func testCoverageStats() {
        service.cacheFromAPI(trackID: "t1", name: "Song 1", artist: "A", bpm: 120)
        service.cacheFromAPI(trackID: "t2", name: "Song 2", artist: "B", bpm: 140)
        service.cacheFromAPI(trackID: "t3", name: "Song 3", artist: "C", bpm: nil)

        let stats = service.coverageStats(forTrackIDs: ["t1", "t2", "t3", "t4"])
        XCTAssertEqual(stats.withBPM, 2)
        XCTAssertEqual(stats.total, 4)
    }

    func testCoverageStatsEmpty() {
        let stats = service.coverageStats(forTrackIDs: [])
        XCTAssertEqual(stats.withBPM, 0)
        XCTAssertEqual(stats.total, 0)
    }

    // MARK: - Confidence & Source Tracking

    func testCacheFromAPISetsVerifiedConfidence() {
        service.cacheFromAPI(trackID: "t1", name: "Song", artist: "A", bpm: 120)

        let descriptor = FetchDescriptor<CachedBPM>(
            predicate: #Predicate { $0.spotifyTrackID == "t1" }
        )
        let cached = try! container.mainContext.fetch(descriptor).first!

        XCTAssertEqual(cached.confidence, .verified)
        XCTAssertEqual(cached.source, .api)
        XCTAssertEqual(cached.confidenceRaw, "verified")
        XCTAssertEqual(cached.sourceRaw, "api")
    }

    func testCacheFromAPIWithNilBPMSetsNilConfidence() {
        service.cacheFromAPI(trackID: "t1", name: "Song", artist: "A", bpm: nil)

        let descriptor = FetchDescriptor<CachedBPM>(
            predicate: #Predicate { $0.spotifyTrackID == "t1" }
        )
        let cached = try! container.mainContext.fetch(descriptor).first!

        XCTAssertNil(cached.confidence)
        XCTAssertNil(cached.source)
        XCTAssertNil(cached.confidenceRaw)
        XCTAssertNil(cached.sourceRaw)
    }

    func testCacheManualSetsManualConfidence() {
        service.cacheManual(trackID: "t1", name: "Song", artist: "A", bpm: 150)

        let descriptor = FetchDescriptor<CachedBPM>(
            predicate: #Predicate { $0.spotifyTrackID == "t1" }
        )
        let cached = try! container.mainContext.fetch(descriptor).first!

        XCTAssertEqual(cached.confidence, .manual)
        XCTAssertEqual(cached.source, .manual)
        XCTAssertEqual(cached.bpm, 150)
    }

    func testCacheFromAPISkipsManualBPM() {
        // First set manual BPM
        service.cacheManual(trackID: "t1", name: "Song", artist: "A", bpm: 150)
        // Then try to overwrite with API BPM
        service.cacheFromAPI(trackID: "t1", name: "Song", artist: "A", bpm: 120)

        let descriptor = FetchDescriptor<CachedBPM>(
            predicate: #Predicate { $0.spotifyTrackID == "t1" }
        )
        let cached = try! container.mainContext.fetch(descriptor).first!

        XCTAssertEqual(cached.bpm, 150, "Manual BPM should be preserved, not overwritten to 120")
        XCTAssertEqual(cached.confidence, .manual, "Confidence should still be manual")
        XCTAssertTrue(cached.lookupAttempted, "lookupAttempted should be updated by cacheFromAPI")
    }

    func testCacheManualOverwritesAPIBPM() {
        // First set API BPM
        service.cacheFromAPI(trackID: "t1", name: "Song", artist: "A", bpm: 120)
        // Then overwrite with manual BPM
        service.cacheManual(trackID: "t1", name: "Song", artist: "A", bpm: 160)

        let descriptor = FetchDescriptor<CachedBPM>(
            predicate: #Predicate { $0.spotifyTrackID == "t1" }
        )
        let cached = try! container.mainContext.fetch(descriptor).first!

        XCTAssertEqual(cached.bpm, 160, "Manual BPM should overwrite API BPM")
        XCTAssertEqual(cached.confidence, .manual)
    }

    func testLazyBackfillReturnsVerifiedForOldRecords() {
        // Simulate pre-migration record: has bpm but no confidenceRaw/sourceRaw
        let record = CachedBPM(spotifyTrackID: "old", trackName: "Old Song", artistName: "A", bpm: 130, lookupAttempted: true)
        container.mainContext.insert(record)
        try! container.mainContext.save()

        let descriptor = FetchDescriptor<CachedBPM>(
            predicate: #Predicate { $0.spotifyTrackID == "old" }
        )
        let cached = try! container.mainContext.fetch(descriptor).first!

        XCTAssertEqual(cached.confidence, .verified, "Lazy backfill should return .verified for old records with bpm")
        XCTAssertEqual(cached.source, .api, "Lazy backfill should return .api for old records with bpm")
        XCTAssertNil(cached.confidenceRaw, "Raw field should still be nil (backfill is in computed property only)")
    }

    func testLazyBackfillReturnsNilForNilBPM() {
        // Record with nil bpm and no confidenceRaw
        let record = CachedBPM(spotifyTrackID: "empty", trackName: "Empty Song", artistName: "A", bpm: nil, lookupAttempted: true)
        container.mainContext.insert(record)
        try! container.mainContext.save()

        let descriptor = FetchDescriptor<CachedBPM>(
            predicate: #Predicate { $0.spotifyTrackID == "empty" }
        )
        let cached = try! container.mainContext.fetch(descriptor).first!

        XCTAssertNil(cached.confidence, "Nil bpm should return nil confidence")
        XCTAssertNil(cached.source, "Nil bpm should return nil source")
    }
}
