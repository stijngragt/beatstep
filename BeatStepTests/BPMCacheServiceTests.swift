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
}
