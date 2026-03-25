import XCTest
@testable import BeatStep

final class ZeroBPMFallbackTests: XCTestCase {
    private let key = "zeroBPMFallback"

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: key)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: key)
        super.tearDown()
    }

    func testHasExactlyThreeCases() {
        let allCases = ZeroBPMFallback.allCases
        XCTAssertEqual(allCases.count, 3)
        XCTAssertTrue(allCases.contains(.skip))
        XCTAssertTrue(allCases.contains(.playRegardless))
        XCTAssertTrue(allCases.contains(.prompt))
    }

    func testDefaultSavedIsSkip() {
        XCTAssertEqual(ZeroBPMFallback.saved, .skip)
    }

    func testSaveAndRetrieveEachCase() {
        for fallback in ZeroBPMFallback.allCases {
            fallback.save()
            XCTAssertEqual(ZeroBPMFallback.saved, fallback, "Failed round-trip for \(fallback)")
        }
    }

    func testDisplayNames() {
        XCTAssertEqual(ZeroBPMFallback.skip.displayName, "Skip")
        XCTAssertEqual(ZeroBPMFallback.playRegardless.displayName, "Play Anyway")
        XCTAssertEqual(ZeroBPMFallback.prompt.displayName, "Ask Me")
    }

    func testCaseIterableProvicesAllThreeCases() {
        let cases = ZeroBPMFallback.allCases
        XCTAssertEqual(cases, [.skip, .playRegardless, .prompt])
    }
}
