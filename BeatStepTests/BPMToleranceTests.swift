import XCTest
@testable import BeatStep

final class BPMToleranceTests: XCTestCase {

    override func tearDown() {
        super.tearDown()
        // Clean up UserDefaults after each test
        UserDefaults.standard.removeObject(forKey: "selectedBPMTolerance")
    }

    // MARK: - Range Values

    func testTightRangeIsThree() {
        XCTAssertEqual(BPMTolerance.tight.range, 3)
    }

    func testNormalRangeIsSeven() {
        XCTAssertEqual(BPMTolerance.normal.range, 7)
    }

    func testLooseRangeIsTwelve() {
        XCTAssertEqual(BPMTolerance.loose.range, 12)
    }

    // MARK: - Default

    func testDefaultToleranceIsNormal() {
        XCTAssertEqual(BPMTolerance.defaultTolerance, .normal)
    }

    // MARK: - Persistence

    func testSaveAndLoadFromUserDefaults() {
        BPMTolerance.tight.save()
        XCTAssertEqual(BPMTolerance.saved, .tight)

        BPMTolerance.loose.save()
        XCTAssertEqual(BPMTolerance.saved, .loose)
    }

    func testSavedReturnsDefaultWhenNoValueStored() {
        UserDefaults.standard.removeObject(forKey: "selectedBPMTolerance")
        XCTAssertEqual(BPMTolerance.saved, .defaultTolerance)
    }

    // MARK: - Display Name

    func testDisplayNameShowsBPMDelta() {
        XCTAssertEqual(BPMTolerance.tight.displayName, "\u{00B1}3 BPM")
        XCTAssertEqual(BPMTolerance.normal.displayName, "\u{00B1}7 BPM")
        XCTAssertEqual(BPMTolerance.loose.displayName, "\u{00B1}12 BPM")
    }

    // MARK: - CaseIterable

    func testCaseIterableIncludesAllThreeCases() {
        XCTAssertEqual(BPMTolerance.allCases.count, 3)
        XCTAssertTrue(BPMTolerance.allCases.contains(.tight))
        XCTAssertTrue(BPMTolerance.allCases.contains(.normal))
        XCTAssertTrue(BPMTolerance.allCases.contains(.loose))
    }
}
