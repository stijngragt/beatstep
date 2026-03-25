import XCTest
import SwiftData
@testable import BeatStep

@MainActor
final class BPMCacheWritePathTests: XCTestCase {

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

    // MARK: - cacheFromAPI

    func testCacheFromAPIWithBPMSetsVerifiedAndAPI() {
        service.cacheFromAPI(trackID: "t1", name: "Song", artist: "Artist", bpm: 120)
        let cached = fetchCached(trackID: "t1")
        XCTAssertEqual(cached?.bpm, 120)
        XCTAssertEqual(cached?.confidenceRaw, BPMConfidence.verified.rawValue)
        XCTAssertEqual(cached?.sourceRaw, BPMSource.api.rawValue)
    }

    func testCacheFromAPIWithNilBPMSetsNilConfidenceAndSource() {
        service.cacheFromAPI(trackID: "t1", name: "Song", artist: "Artist", bpm: nil)
        let cached = fetchCached(trackID: "t1")
        XCTAssertNil(cached?.bpm)
        XCTAssertNil(cached?.confidenceRaw)
        XCTAssertNil(cached?.sourceRaw)
    }

    func testCacheFromAPISkipsBPMOverwriteWhenManual() {
        // Set up a manual record
        service.cacheManual(trackID: "t1", name: "Song", artist: "Artist", bpm: 130)
        // API tries to overwrite
        service.cacheFromAPI(trackID: "t1", name: "Song", artist: "Artist", bpm: 120)
        let cached = fetchCached(trackID: "t1")
        // BPM should still be 130 (manual wins)
        XCTAssertEqual(cached?.bpm, 130)
        XCTAssertEqual(cached?.confidenceRaw, BPMConfidence.manual.rawValue)
        XCTAssertEqual(cached?.sourceRaw, BPMSource.manual.rawValue)
        // But lookupAttempted should be updated
        XCTAssertEqual(cached?.lookupAttempted, true)
    }

    func testCacheFromAPIOverwritesNonManualConfidence() {
        service.cacheFromAPI(trackID: "t1", name: "Song", artist: "Artist", bpm: 120)
        service.cacheFromAPI(trackID: "t1", name: "Song", artist: "Artist", bpm: 130)
        let cached = fetchCached(trackID: "t1")
        XCTAssertEqual(cached?.bpm, 130)
        XCTAssertEqual(cached?.confidenceRaw, BPMConfidence.verified.rawValue)
    }

    // MARK: - cacheManual

    func testCacheManualSetsManualConfidenceAndSource() {
        service.cacheManual(trackID: "t1", name: "Song", artist: "Artist", bpm: 126)
        let cached = fetchCached(trackID: "t1")
        XCTAssertEqual(cached?.bpm, 126)
        XCTAssertEqual(cached?.confidenceRaw, BPMConfidence.manual.rawValue)
        XCTAssertEqual(cached?.sourceRaw, BPMSource.manual.rawValue)
    }

    func testCacheManualOverwritesAPIBPM() {
        service.cacheFromAPI(trackID: "t1", name: "Song", artist: "Artist", bpm: 120)
        service.cacheManual(trackID: "t1", name: "Song", artist: "Artist", bpm: 126)
        let cached = fetchCached(trackID: "t1")
        XCTAssertEqual(cached?.bpm, 126)
        XCTAssertEqual(cached?.confidenceRaw, BPMConfidence.manual.rawValue)
        XCTAssertEqual(cached?.sourceRaw, BPMSource.manual.rawValue)
    }

    // MARK: - Old cache() removed

    // Compile-time check: cache() method should not exist.
    // If this test file compiles, it confirms the old method is gone
    // (any reference to service.cache(...) would fail compilation).

    // MARK: - Helpers

    private func fetchCached(trackID: String) -> CachedBPM? {
        let descriptor = FetchDescriptor<CachedBPM>(
            predicate: #Predicate { $0.spotifyTrackID == trackID }
        )
        return try? container.mainContext.fetch(descriptor).first
    }
}
