import XCTest
@testable import BeatStep

final class ZoneSelectionTests: XCTestCase {

    override func tearDown() {
        super.tearDown()
        UserDefaults.standard.removeObject(forKey: "selectedRunZoneId")
        UserDefaults.standard.removeObject(forKey: "selectedRunZoneIds")
    }

    // MARK: - selectedZoneId Persistence

    func testSelectedZoneIdDefaultsToNil() {
        UserDefaults.standard.removeObject(forKey: "selectedRunZoneId")
        XCTAssertNil(RunZone.selectedZoneId)
    }

    func testSelectedZoneIdRoundTrip() {
        RunZone.selectedZoneId = 3
        XCTAssertEqual(RunZone.selectedZoneId, 3)
    }

    func testSelectedZoneIdNilStoresZero() {
        RunZone.selectedZoneId = nil
        let raw = UserDefaults.standard.integer(forKey: "selectedRunZoneId")
        XCTAssertEqual(raw, 0)
    }

    // MARK: - Zone to RunMode Mapping

    func testZoneToRunModeMapping() {
        RunZone.selectedZoneId = 3
        let zones = RunZone.saved
        let zone = zones.first { $0.id == 3 }
        XCTAssertNotNil(zone)
        XCTAssertEqual(zone?.bpm, RunZone.saved[2].bpm)
    }

    func testFreeModeMappingWhenNil() {
        RunZone.selectedZoneId = nil
        XCTAssertNil(RunZone.selectedZoneId, "nil selectedZoneId means free mode")
    }

    // MARK: - selectedZoneIds (Multi-Zone) Persistence

    func testSelectedZoneIdsDefaultsToEmptySet() {
        UserDefaults.standard.removeObject(forKey: "selectedRunZoneIds")
        UserDefaults.standard.removeObject(forKey: "selectedRunZoneId")
        XCTAssertEqual(RunZone.selectedZoneIds, Set<Int>())
    }

    func testSelectedZoneIdsRoundTrip() {
        RunZone.selectedZoneIds = Set([1, 3])
        XCTAssertEqual(RunZone.selectedZoneIds, Set([1, 3]))
    }

    func testSelectedZoneIdsMigrationFromSingleId() {
        UserDefaults.standard.removeObject(forKey: "selectedRunZoneIds")
        UserDefaults.standard.set(3, forKey: "selectedRunZoneId")
        XCTAssertEqual(RunZone.selectedZoneIds, Set([3]))
    }

    func testSelectedZoneIdsEmptySetPersists() {
        RunZone.selectedZoneIds = Set<Int>()
        XCTAssertEqual(RunZone.selectedZoneIds, Set<Int>())
    }
}
