import XCTest
import SwiftUI
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
}
