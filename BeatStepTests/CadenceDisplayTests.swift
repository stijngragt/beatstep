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
}
