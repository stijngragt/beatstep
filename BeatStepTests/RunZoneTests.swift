import XCTest
@testable import BeatStep

final class RunZoneTests: XCTestCase {

    override func tearDown() {
        super.tearDown()
        UserDefaults.standard.removeObject(forKey: "runZoneBPMs")
    }

    // MARK: - Defaults

    func testDefaultsReturnsFiveZones() {
        XCTAssertEqual(RunZone.defaults.count, 5)
    }

    func testDefaultZoneValues() {
        let defaults = RunZone.defaults
        XCTAssertEqual(defaults[0].id, 1)
        XCTAssertEqual(defaults[0].name, "Recovery")
        XCTAssertEqual(defaults[0].bpm, 155)

        XCTAssertEqual(defaults[1].id, 2)
        XCTAssertEqual(defaults[1].name, "Endurance")
        XCTAssertEqual(defaults[1].bpm, 165)

        XCTAssertEqual(defaults[2].id, 3)
        XCTAssertEqual(defaults[2].name, "Tempo")
        XCTAssertEqual(defaults[2].bpm, 174)

        XCTAssertEqual(defaults[3].id, 4)
        XCTAssertEqual(defaults[3].name, "Threshold")
        XCTAssertEqual(defaults[3].bpm, 178)

        XCTAssertEqual(defaults[4].id, 5)
        XCTAssertEqual(defaults[4].name, "Max")
        XCTAssertEqual(defaults[4].bpm, 185)
    }

    // MARK: - Display Label

    func testDisplayLabel() {
        let zone = RunZone.defaults[0]
        XCTAssertEqual(zone.displayLabel, "Z1 Recovery")
    }

    // MARK: - Persistence

    func testSavedReturnsDefaultsWhenNoDataStored() {
        UserDefaults.standard.removeObject(forKey: "runZoneBPMs")
        let saved = RunZone.saved
        XCTAssertEqual(saved.count, 5)
        XCTAssertEqual(saved[0].bpm, 155)
        XCTAssertEqual(saved[4].bpm, 185)
    }

    func testSaveAllAndLoadRoundTrip() {
        var zones = RunZone.defaults
        zones[0].bpm = 140
        zones[2].bpm = 180

        RunZone.saveAll(zones)

        let loaded = RunZone.saved
        XCTAssertEqual(loaded[0].bpm, 140)
        XCTAssertEqual(loaded[1].bpm, 165) // unchanged
        XCTAssertEqual(loaded[2].bpm, 180)
        XCTAssertEqual(loaded[3].bpm, 178) // unchanged
        XCTAssertEqual(loaded[4].bpm, 185) // unchanged
    }

    func testResetToDefaultsClearsPersistedData() {
        var zones = RunZone.defaults
        zones[0].bpm = 140
        RunZone.saveAll(zones)

        RunZone.resetToDefaults()

        let loaded = RunZone.saved
        XCTAssertEqual(loaded[0].bpm, 155) // back to default
    }

    // MARK: - Identifiable & Equatable

    func testZoneIsIdentifiable() {
        let zone = RunZone.defaults[0]
        XCTAssertEqual(zone.id, 1)
    }

    func testZoneEquatable() {
        let a = RunZone.defaults[0]
        var b = RunZone.defaults[0]
        XCTAssertEqual(a, b)

        b.bpm = 999
        XCTAssertNotEqual(a, b)
    }
}
