import XCTest
import SwiftUI
import SwiftData
@testable import BeatStep

final class BPMConfidenceBadgeTests: XCTestCase {

    // MARK: - Icon Name Tests

    func testVerifiedIconName() {
        XCTAssertEqual(BPMConfidence.verified.iconName, "checkmark.seal.fill")
    }

    func testManualIconName() {
        XCTAssertEqual(BPMConfidence.manual.iconName, "hand.raised.fill")
    }

    func testApproximateIconName() {
        XCTAssertEqual(BPMConfidence.approximate.iconName, "tilde")
    }

    // MARK: - Color Tests

    func testVerifiedColor() {
        XCTAssertEqual(BPMConfidence.verified.color, .stateSuccess)
    }

    func testManualColor() {
        XCTAssertEqual(BPMConfidence.manual.color, .stateWarning)
    }

    func testApproximateColor() {
        XCTAssertEqual(BPMConfidence.approximate.color, .stateApproximate)
    }

    // MARK: - BPMInfo Tests

    func testBPMInfoEmpty() {
        let info = BPMInfo.empty
        XCTAssertNil(info.bpm)
        XCTAssertNil(info.confidence)
    }

    func testBPMInfoEquatable() {
        let a = BPMInfo(bpm: 120, confidence: .verified)
        let b = BPMInfo(bpm: 120, confidence: .verified)
        XCTAssertEqual(a, b)
    }

    // MARK: - Service Tests

    @MainActor
    func testGetBPMInfoReturnsConfidence() throws {
        let schema = Schema([CachedBPM.self, ScannedPlaylist.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let service = BPMCacheService.shared
        service.setContainer(container)

        service.cacheFromAPI(trackID: "track_1", name: "Run Boy Run", artist: "Woodkid", bpm: 172)
        let info = service.getBPMInfo(forTrackID: "track_1")

        XCTAssertEqual(info.bpm, 172)
        XCTAssertEqual(info.confidence, .verified)
    }

    @MainActor
    func testGetBPMInfoEmptyForUnknown() throws {
        let schema = Schema([CachedBPM.self, ScannedPlaylist.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let service = BPMCacheService.shared
        service.setContainer(container)

        let info = service.getBPMInfo(forTrackID: "nonexistent")
        XCTAssertEqual(info, BPMInfo.empty)
    }
}
