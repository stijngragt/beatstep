import XCTest
@testable import BeatStep

final class PlaylistCoverageTests: XCTestCase {

    // MARK: - Percentage Calculation

    func testPercentageCalculation() {
        // Stub: PlaylistCoverage(tracksWithBPM: 42, totalTracks: 50).percentage == 0.84
        XCTFail("Wave 0 stub — implement PlaylistCoverage struct first")
    }

    func testPercentageZeroTotalTracks() {
        // Stub: PlaylistCoverage(tracksWithBPM: 0, totalTracks: 0).percentage == 0
        XCTFail("Wave 0 stub — implement PlaylistCoverage struct first")
    }

    // MARK: - Status Color Thresholds

    func testStatusColorGreenAbove80() {
        // Stub: 85% -> stateSuccess
        XCTFail("Wave 0 stub — implement PlaylistCoverage struct first")
    }

    func testStatusColorYellow40To80() {
        // Stub: 50% -> stateWarning
        XCTFail("Wave 0 stub — implement PlaylistCoverage struct first")
    }

    func testStatusColorRedBelow40() {
        // Stub: 20% -> stateError
        XCTFail("Wave 0 stub — implement PlaylistCoverage struct first")
    }

    // MARK: - Text Format

    func testTextFormat() {
        // Stub: PlaylistCoverage(tracksWithBPM: 42, totalTracks: 50).text == "42/50 BPM"
        XCTFail("Wave 0 stub — implement PlaylistCoverage struct first")
    }
}
