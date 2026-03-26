import XCTest
@testable import BeatStep

final class PlaylistCoverageTests: XCTestCase {

    // MARK: - Percentage Calculation

    func testPercentageCalculation() {
        let coverage = PlaylistCoverage(tracksWithBPM: 42, totalTracks: 50)
        XCTAssertEqual(coverage.percentage, 0.84, accuracy: 0.001)
    }

    func testPercentageZeroTotalTracks() {
        let coverage = PlaylistCoverage(tracksWithBPM: 0, totalTracks: 0)
        XCTAssertEqual(coverage.percentage, 0)
    }

    // MARK: - Status Color Thresholds

    func testStatusColorGreenAbove80() {
        let coverage = PlaylistCoverage(tracksWithBPM: 85, totalTracks: 100)
        XCTAssertEqual(coverage.statusColor, .stateSuccess)
    }

    func testStatusColorYellow40To80() {
        let coverage = PlaylistCoverage(tracksWithBPM: 50, totalTracks: 100)
        XCTAssertEqual(coverage.statusColor, .stateWarning)
    }

    func testStatusColorRedBelow40() {
        let coverage = PlaylistCoverage(tracksWithBPM: 20, totalTracks: 100)
        XCTAssertEqual(coverage.statusColor, .stateError)
    }

    // MARK: - Text Format

    func testTextFormat() {
        let coverage = PlaylistCoverage(tracksWithBPM: 42, totalTracks: 50)
        XCTAssertEqual(coverage.text, "42/50 BPM")
    }
}
