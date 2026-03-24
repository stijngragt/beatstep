import XCTest
@testable import BeatStep

final class LongPressStopTests: XCTestCase {

    // MARK: - Progress Calculation

    func testProgressAtZeroElapsedReturnsZero() {
        let result = LongPressStopButton.progress(elapsed: 0, duration: 2)
        XCTAssertEqual(result, 0.0, accuracy: 0.001)
    }

    func testProgressAtHalfDurationReturnsHalf() {
        let result = LongPressStopButton.progress(elapsed: 1, duration: 2)
        XCTAssertEqual(result, 0.5, accuracy: 0.001)
    }

    func testProgressAtFullDurationReturnsOne() {
        let result = LongPressStopButton.progress(elapsed: 2, duration: 2)
        XCTAssertEqual(result, 1.0, accuracy: 0.001)
    }

    func testProgressBeyondDurationClampsToOne() {
        let result = LongPressStopButton.progress(elapsed: 3, duration: 2)
        XCTAssertEqual(result, 1.0, accuracy: 0.001)
    }

    func testProgressNegativeElapsedClampsToZero() {
        let result = LongPressStopButton.progress(elapsed: -1, duration: 2)
        XCTAssertEqual(result, 0.0, accuracy: 0.001)
    }
}
