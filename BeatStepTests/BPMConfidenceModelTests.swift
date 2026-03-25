import XCTest
import SwiftData
@testable import BeatStep

@MainActor
final class BPMConfidenceModelTests: XCTestCase {

    private var container: ModelContainer!

    override func setUp() async throws {
        try await super.setUp()
        let schema = Schema([CachedBPM.self, ScannedPlaylist.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
    }

    override func tearDown() async throws {
        container = nil
        try await super.tearDown()
    }

    // MARK: - BPMConfidence Enum

    func testBPMConfidenceHasThreeCases() {
        XCTAssertEqual(BPMConfidence.allCases.count, 3)
        XCTAssertEqual(BPMConfidence.verified.rawValue, "verified")
        XCTAssertEqual(BPMConfidence.approximate.rawValue, "approximate")
        XCTAssertEqual(BPMConfidence.manual.rawValue, "manual")
    }

    // MARK: - BPMSource Enum

    func testBPMSourceHasTwoCases() {
        XCTAssertEqual(BPMSource.allCases.count, 2)
        XCTAssertEqual(BPMSource.api.rawValue, "api")
        XCTAssertEqual(BPMSource.manual.rawValue, "manual")
    }

    // MARK: - CachedBPM Lazy Backfill

    func testConfidenceReturnsVerifiedWhenRawNilAndBPMNonNil() {
        let cached = CachedBPM(spotifyTrackID: "t1", trackName: "Song", artistName: "Artist", bpm: 120)
        XCTAssertNil(cached.confidenceRaw)
        XCTAssertEqual(cached.confidence, .verified)
    }

    func testSourceReturnsAPIWhenRawNilAndBPMNonNil() {
        let cached = CachedBPM(spotifyTrackID: "t1", trackName: "Song", artistName: "Artist", bpm: 120)
        XCTAssertNil(cached.sourceRaw)
        XCTAssertEqual(cached.source, .api)
    }

    func testConfidenceReturnsNilWhenBPMNil() {
        let cached = CachedBPM(spotifyTrackID: "t1", trackName: "Song", artistName: "Artist", bpm: nil)
        XCTAssertNil(cached.confidence)
    }

    func testSourceReturnsNilWhenBPMNil() {
        let cached = CachedBPM(spotifyTrackID: "t1", trackName: "Song", artistName: "Artist", bpm: nil)
        XCTAssertNil(cached.source)
    }

    func testConfidenceReturnsStoredValueWhenRawSet() {
        let cached = CachedBPM(spotifyTrackID: "t1", trackName: "Song", artistName: "Artist", bpm: 120)
        cached.confidenceRaw = BPMConfidence.manual.rawValue
        XCTAssertEqual(cached.confidence, .manual)
    }

    func testSourceReturnsStoredValueWhenRawSet() {
        let cached = CachedBPM(spotifyTrackID: "t1", trackName: "Song", artistName: "Artist", bpm: 120)
        cached.sourceRaw = BPMSource.manual.rawValue
        XCTAssertEqual(cached.source, .manual)
    }

    // MARK: - Confidence Setter

    func testSettingConfidenceWritesToRaw() {
        let cached = CachedBPM(spotifyTrackID: "t1", trackName: "Song", artistName: "Artist", bpm: 120)
        cached.confidence = .manual
        XCTAssertEqual(cached.confidenceRaw, "manual")
    }

    func testSettingConfidenceNilWritesNilRaw() {
        let cached = CachedBPM(spotifyTrackID: "t1", trackName: "Song", artistName: "Artist", bpm: 120)
        cached.confidenceRaw = "manual"
        cached.confidence = nil
        XCTAssertNil(cached.confidenceRaw)
    }

    // MARK: - Convenience Accessors

    func testIsManualReturnsTrue() {
        let cached = CachedBPM(spotifyTrackID: "t1", trackName: "Song", artistName: "Artist", bpm: 120)
        cached.confidenceRaw = BPMConfidence.manual.rawValue
        XCTAssertTrue(cached.isManual)
    }

    func testIsVerifiedReturnsTrue() {
        let cached = CachedBPM(spotifyTrackID: "t1", trackName: "Song", artistName: "Artist", bpm: 120)
        // Lazy backfill: nil raw + non-nil bpm = .verified
        XCTAssertTrue(cached.isVerified)
    }
}
