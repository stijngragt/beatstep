import XCTest
@testable import BeatStep

final class PacePresetTests: XCTestCase {

    func testEasyJogBPM() {
        XCTAssertEqual(PacePreset.easyJog.bpm, 150)
    }

    func testSteadyBPM() {
        XCTAssertEqual(PacePreset.steady.bpm, 160)
    }

    func testTempoBPM() {
        XCTAssertEqual(PacePreset.tempo.bpm, 170)
    }

    func testFastBPM() {
        XCTAssertEqual(PacePreset.fast.bpm, 180)
    }

    func testSprintBPM() {
        XCTAssertEqual(PacePreset.sprint.bpm, 190)
    }

    func testCustomBPMIsNil() {
        XCTAssertNil(PacePreset.custom.bpm)
    }

    func testDisplayNames() {
        XCTAssertEqual(PacePreset.easyJog.displayName, "Easy Jog")
        XCTAssertEqual(PacePreset.steady.displayName, "Steady")
        XCTAssertEqual(PacePreset.tempo.displayName, "Tempo")
        XCTAssertEqual(PacePreset.fast.displayName, "Fast")
        XCTAssertEqual(PacePreset.sprint.displayName, "Sprint")
        XCTAssertEqual(PacePreset.custom.displayName, "Custom")
    }

    func testAllCasesCount() {
        XCTAssertEqual(PacePreset.allCases.count, 6)
    }
}
