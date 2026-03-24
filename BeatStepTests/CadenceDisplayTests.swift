import XCTest
import SwiftUI
@testable import BeatStep

final class CadenceDisplayTests: XCTestCase {

    // MARK: - SyncQuality.color Mapping

    func testInSyncColorReturnsSyncInSyncToken() {
        XCTAssertEqual(SyncQuality.inSync.color, Color.syncInSync)
    }

    func testDriftingColorReturnsSyncDriftingToken() {
        XCTAssertEqual(SyncQuality.drifting.color, Color.syncDrifting)
    }

    func testMismatchedColorReturnsSyncMismatchedToken() {
        XCTAssertEqual(SyncQuality.mismatched.color, Color.syncMismatched)
    }

    func testAllCasesHaveNonNilColor() {
        for quality in SyncQuality.allCases {
            // Color is a value type, so it's never nil — but verify the property exists
            // and returns a valid Color by checking it's not equal to Color.clear
            XCTAssertNotEqual(quality.color, Color.clear, "\(quality) should have a non-clear color")
        }
    }

    // MARK: - ZoneBandView Position Computation

    func testZoneBandPositionAtMinimumReturnsZero() {
        // Band spans targetBPM - 2*tolerance to targetBPM + 2*tolerance
        // With target=174, tolerance=7: band is 160..188
        let position = ZoneBandView.position(cadence: 160, targetBPM: 174, toleranceRange: 7)
        XCTAssertEqual(position, 0.0, accuracy: 0.001)
    }

    func testZoneBandPositionAtMaximumReturnsOne() {
        let position = ZoneBandView.position(cadence: 188, targetBPM: 174, toleranceRange: 7)
        XCTAssertEqual(position, 1.0, accuracy: 0.001)
    }

    func testZoneBandPositionAtCenterReturnsHalf() {
        let position = ZoneBandView.position(cadence: 174, targetBPM: 174, toleranceRange: 7)
        XCTAssertEqual(position, 0.5, accuracy: 0.001)
    }

    func testZoneBandPositionBelowMinimumClampsToZero() {
        let position = ZoneBandView.position(cadence: 140, targetBPM: 174, toleranceRange: 7)
        XCTAssertEqual(position, 0.0, accuracy: 0.001)
    }

    func testZoneBandPositionAboveMaximumClampsToOne() {
        let position = ZoneBandView.position(cadence: 200, targetBPM: 174, toleranceRange: 7)
        XCTAssertEqual(position, 1.0, accuracy: 0.001)
    }

    func testZoneBandSpansTwiceToleranceRange() {
        // Band width should be 4 * toleranceRange (2x on each side)
        // At targetBPM - 2*tolerance = min (0.0), at targetBPM + 2*tolerance = max (1.0)
        // One tolerance unit above min should be 0.25
        let position = ZoneBandView.position(cadence: 167, targetBPM: 174, toleranceRange: 7)
        XCTAssertEqual(position, 0.25, accuracy: 0.001)
    }

    // MARK: - RampPhaseIndicator Progress Computation

    func testRampProgressWarmUpAtStartReturnsZero() {
        let progress = RampPhaseIndicator.progress(phase: .warmUp, effectiveBPM: 140, targetBPM: 174)
        XCTAssertEqual(progress, 0.0, accuracy: 0.001)
    }

    func testRampProgressWarmUpAtTargetReturnsOne() {
        let progress = RampPhaseIndicator.progress(phase: .warmUp, effectiveBPM: 174, targetBPM: 174)
        XCTAssertEqual(progress, 1.0, accuracy: 0.001)
    }

    func testRampProgressWarmUpAtMidpointReturnsHalf() {
        // Midpoint between 140 and 174 is 157
        let progress = RampPhaseIndicator.progress(phase: .warmUp, effectiveBPM: 157, targetBPM: 174)
        XCTAssertEqual(progress, 0.5, accuracy: 0.001)
    }

    func testRampProgressAtPaceAlwaysReturnsOne() {
        let progress = RampPhaseIndicator.progress(phase: .atPace, effectiveBPM: 160, targetBPM: 174)
        XCTAssertEqual(progress, 1.0, accuracy: 0.001)
    }

    func testRampProgressCoolDownAtTargetReturnsOne() {
        let progress = RampPhaseIndicator.progress(phase: .coolDown, effectiveBPM: 174, targetBPM: 174)
        XCTAssertEqual(progress, 1.0, accuracy: 0.001)
    }

    func testRampProgressCoolDownAtStartReturnsZero() {
        let progress = RampPhaseIndicator.progress(phase: .coolDown, effectiveBPM: 140, targetBPM: 174)
        XCTAssertEqual(progress, 0.0, accuracy: 0.001)
    }
}
