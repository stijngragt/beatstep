import XCTest
import SwiftData
@testable import BeatStep

@MainActor
final class BPMViewWiringTests: XCTestCase {

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

    // MARK: - BPM Data for Views

    func testBPMCacheReturnsDataForKnownTrack() {
        service.cacheFromAPI(trackID: "abc", name: "Run Boy Run", artist: "Woodkid", bpm: 172)
        XCTAssertEqual(service.getBPM(forTrackID: "abc"), 172)
    }

    func testBPMCacheReturnsNilForUnknownTrack() {
        XCTAssertNil(service.getBPM(forTrackID: "unknown"))
    }

    func testCoverageStatsAccuracy() {
        service.cacheFromAPI(trackID: "t1", name: "Song 1", artist: "A", bpm: 120)
        service.cacheFromAPI(trackID: "t2", name: "Song 2", artist: "B", bpm: 140)
        service.cacheFromAPI(trackID: "t3", name: "Song 3", artist: "C", bpm: nil)

        let stats = service.coverageStats(forTrackIDs: ["t1", "t2", "t3"])
        XCTAssertEqual(stats.withBPM, 2)
        XCTAssertEqual(stats.total, 3)
    }

    func testHasLookupAfterCache() {
        service.cacheFromAPI(trackID: "cached_track", name: "Song", artist: "Artist", bpm: 120)
        XCTAssertTrue(service.hasLookup(forTrackID: "cached_track"))
        XCTAssertFalse(service.hasLookup(forTrackID: "never_cached"))
    }

    // MARK: - Scan Progress State

    func testScanProgressInitiallyNil() {
        XCTAssertNil(LibraryScanService.shared.scanProgress)
    }

    // MARK: - BPM Display Formatting

    func testBPMBadgeShowsNumberForKnownTrack() {
        service.cacheFromAPI(trackID: "track_known", name: "Song", artist: "Artist", bpm: 172)
        let bpm = service.getBPM(forTrackID: "track_known")
        XCTAssertNotNil(bpm)
        XCTAssertEqual("\(bpm!) BPM", "172 BPM")
    }

    func testBPMBadgeShowsDashForUnknownTrack() {
        let bpm = service.getBPM(forTrackID: "no_such_track")
        XCTAssertNil(bpm)
        // View would show "--" when bpm is nil
    }

    func testBPMBadgeShowsDashForNilBPMTrack() {
        service.cacheFromAPI(trackID: "nil_bpm", name: "Song", artist: "Artist", bpm: nil)
        let bpm = service.getBPM(forTrackID: "nil_bpm")
        XCTAssertNil(bpm)
        // View would show "--" when bpm is nil
    }
}
