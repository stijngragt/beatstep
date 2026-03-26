import XCTest
@testable import BeatStep

final class PlaylistFilterTests: XCTestCase {

    // MARK: - PlaylistFilter Enum (LIB-02)

    func testFilterAllReturnsAllPlaylists() {
        // Stub: Will test that PlaylistFilter.all does not exclude any playlists
        // Implementation in Task 1 will make PlaylistFilter enum available
        XCTFail("Wave 0 stub — implement PlaylistFilter enum first")
    }

    func testFilterAnalyzedReturnsOnlyAnalyzed() {
        // Stub: Will test that .analyzed filter returns only playlists with coverageData entries
        XCTFail("Wave 0 stub — implement PlaylistFilter enum first")
    }

    func testFilterUnanalyzedReturnsOnlyUnanalyzed() {
        // Stub: Will test that .unanalyzed filter returns only playlists without coverageData entries
        XCTFail("Wave 0 stub — implement PlaylistFilter enum first")
    }

    // MARK: - Search Filtering (LIB-01)

    func testSearchFiltersPlaylistsByName() {
        // Stub: Will test that searchText filters playlists by case-insensitive name match
        XCTFail("Wave 0 stub — implement filteredPlaylists first")
    }

    func testSearchAndFilterCompound() {
        // Stub: Will test that search + filter stack (e.g., "Analyzed" + search "run")
        XCTFail("Wave 0 stub — implement filteredPlaylists first")
    }
}
