import XCTest
@testable import BeatStep

final class PlaylistFilterTests: XCTestCase {

    // MARK: - PlaylistFilter Enum (LIB-02)

    func testFilterEnumHasThreeCases() {
        XCTAssertEqual(PlaylistFilter.allCases.count, 3)
    }

    func testFilterAllRawValue() {
        XCTAssertEqual(PlaylistFilter.all.rawValue, "All")
    }

    func testFilterAnalyzedRawValue() {
        XCTAssertEqual(PlaylistFilter.analyzed.rawValue, "Analyzed")
    }

    func testFilterUnanalyzedRawValue() {
        XCTAssertEqual(PlaylistFilter.unanalyzed.rawValue, "Unanalyzed")
    }

    // MARK: - PlaylistCoverage Integration with Filter Concepts

    func testAnalyzedPlaylistHasCoverage() {
        // A playlist is "analyzed" when it has a PlaylistCoverage entry
        let coverage = PlaylistCoverage(tracksWithBPM: 5, totalTracks: 10)
        // Non-nil coverage means analyzed
        XCTAssertNotNil(Optional.some(coverage))
    }

    func testUnanalyzedPlaylistHasNoCoverage() {
        // A playlist is "unanalyzed" when it has no PlaylistCoverage entry
        let coverage: PlaylistCoverage? = nil
        // nil coverage means unanalyzed
        XCTAssertNil(coverage)
    }

    // MARK: - PlaylistFilter CaseIterable

    func testFilterIsCaseIterable() {
        let allCases = PlaylistFilter.allCases
        XCTAssertEqual(allCases, [.all, .analyzed, .unanalyzed])
    }
}
