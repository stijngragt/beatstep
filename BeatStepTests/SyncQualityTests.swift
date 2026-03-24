import XCTest
@testable import BeatStep

final class SyncQualityTests: XCTestCase {

    // MARK: - Normal Tolerance (range: 7)

    func testInSyncWithinNormalTolerance() {
        XCTAssertEqual(SyncQuality.from(delta: 5, tolerance: .normal), .inSync)
    }

    func testInSyncWithNegativeDelta() {
        XCTAssertEqual(SyncQuality.from(delta: -5, tolerance: .normal), .inSync)
    }

    func testInSyncAtExactNormalBoundary() {
        XCTAssertEqual(SyncQuality.from(delta: 7, tolerance: .normal), .inSync)
    }

    func testDriftingAboveNormalRange() {
        XCTAssertEqual(SyncQuality.from(delta: 10, tolerance: .normal), .drifting)
    }

    func testDriftingAtDoubleNormalBoundary() {
        XCTAssertEqual(SyncQuality.from(delta: 14, tolerance: .normal), .drifting)
    }

    func testMismatchedAboveDoubleNormalRange() {
        XCTAssertEqual(SyncQuality.from(delta: 15, tolerance: .normal), .mismatched)
    }

    // MARK: - Tight Tolerance (range: 3)

    func testInSyncAtZeroDeltaTight() {
        XCTAssertEqual(SyncQuality.from(delta: 0, tolerance: .tight), .inSync)
    }

    func testDriftingAboveTightRange() {
        XCTAssertEqual(SyncQuality.from(delta: 4, tolerance: .tight), .drifting)
    }

    func testMismatchedAboveDoubleTightRange() {
        XCTAssertEqual(SyncQuality.from(delta: 7, tolerance: .tight), .mismatched)
    }

    // MARK: - Loose Tolerance (range: 12)

    func testInSyncAtExactLooseBoundary() {
        XCTAssertEqual(SyncQuality.from(delta: 12, tolerance: .loose), .inSync)
    }

    func testMismatchedAboveDoubleLooseRange() {
        XCTAssertEqual(SyncQuality.from(delta: 25, tolerance: .loose), .mismatched)
    }

    func testDriftingWithinDoubleLooseRange() {
        XCTAssertEqual(SyncQuality.from(delta: 20, tolerance: .loose), .drifting)
    }

    // MARK: - Display Labels

    func testDisplayLabelInSync() {
        XCTAssertEqual(SyncQuality.inSync.displayLabel, "In Sync")
    }

    func testDisplayLabelDrifting() {
        XCTAssertEqual(SyncQuality.drifting.displayLabel, "Drifting")
    }

    func testDisplayLabelMismatched() {
        XCTAssertEqual(SyncQuality.mismatched.displayLabel, "Mismatched")
    }

    // MARK: - TempoMode

    func testTempoModeDefaultIsSaved() {
        // Clear any saved value
        UserDefaults.standard.removeObject(forKey: "selectedTempoMode")
        XCTAssertEqual(TempoMode.saved, .oneToOne)
    }

    func testTempoModeSaveAndRestore() {
        TempoMode.half.save()
        XCTAssertEqual(TempoMode.saved, .half)
        // Clean up
        UserDefaults.standard.removeObject(forKey: "selectedTempoMode")
    }

    func testTempoModeDisplayNames() {
        XCTAssertEqual(TempoMode.oneToOne.displayName, "1:1")
        XCTAssertEqual(TempoMode.half.displayName, "1/2")
    }

    func testTempoModeIsCaseIterable() {
        XCTAssertEqual(TempoMode.allCases.count, 2)
    }
}
