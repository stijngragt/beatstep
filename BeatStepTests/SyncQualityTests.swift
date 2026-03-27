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

    // MARK: - Tempo Normalization

    func testHalfTempoTrackReturnsInSync() {
        // Runner at 160 SPM, track at 80 BPM -> 2x track = 160, delta = 0
        XCTAssertEqual(SyncQuality.from(spm: 160, trackBPM: 80, tolerance: .normal), .inSync)
    }

    func testDoubleTempoTrackReturnsInSync() {
        // Runner at 85 SPM, track at 170 BPM -> 0.5x track = 85, delta = 0
        XCTAssertEqual(SyncQuality.from(spm: 85, trackBPM: 170, tolerance: .normal), .inSync)
    }

    func testRawMatchReturnsInSync() {
        // Runner at 174 SPM, track at 174 BPM -> delta = 0
        XCTAssertEqual(SyncQuality.from(spm: 174, trackBPM: 174, tolerance: .normal), .inSync)
    }

    func testRawDeltaWithinToleranceReturnsInSync() {
        // Runner at 174 SPM, track at 180 BPM -> delta 6 <= range 7
        XCTAssertEqual(SyncQuality.from(spm: 174, trackBPM: 180, tolerance: .normal), .inSync)
    }

    func testDriftingWhenBeyondSingleRange() {
        // Runner at 160 SPM, track at 150 BPM -> raw delta 10 > 7 but <= 14
        XCTAssertEqual(SyncQuality.from(spm: 160, trackBPM: 150, tolerance: .normal), .drifting)
    }

    func testMismatchedWhenAllCandidatesFarOff() {
        // Runner at 160 SPM, track at 120 BPM
        // raw delta 40, half (60) delta 100, double (240) delta 80 -- all > 14
        XCTAssertEqual(SyncQuality.from(spm: 160, trackBPM: 120, tolerance: .normal), .mismatched)
    }

    func testZeroBPMReturnsMismatched() {
        XCTAssertEqual(SyncQuality.from(spm: 160, trackBPM: 0, tolerance: .normal), .mismatched)
    }

    // MARK: - Icon Names

    func testIconNameInSync() {
        XCTAssertEqual(SyncQuality.inSync.iconName, "waveform.path.ecg")
    }

    func testIconNameDrifting() {
        XCTAssertEqual(SyncQuality.drifting.iconName, "waveform.badge.minus")
    }

    func testIconNameMismatched() {
        XCTAssertEqual(SyncQuality.mismatched.iconName, "waveform.slash")
    }
}
