import XCTest
@testable import BeatStep

final class ActiveRunViewTests: XCTestCase {

    /// Verify ActiveRunView can be instantiated with nil zone (free mode).
    /// This is a build-verification test confirming the view compiles
    /// and all sub-component interfaces are satisfied.
    func testActiveRunViewInstantiatesWithNilZone() {
        let playlist = SpotifyPlaylist(
            id: "test", name: "Test", description: nil, images: nil,
            tracks: TracksRef(total: 10),
            owner: PlaylistOwner(displayName: "Test")
        )
        let view = ActiveRunView(
            playlist: playlist,
            tracks: [],
            selectedZoneId: nil
        )
        // View instantiated without crash -- free mode (no zone)
        XCTAssertNil(view.selectedZoneId)
    }

    /// Verify ActiveRunView accepts a zone ID for guided mode.
    func testActiveRunViewInstantiatesWithZoneId() {
        let playlist = SpotifyPlaylist(
            id: "test", name: "Test", description: nil, images: nil,
            tracks: TracksRef(total: 10),
            owner: PlaylistOwner(displayName: "Test")
        )
        let view = ActiveRunView(
            playlist: playlist,
            tracks: [],
            selectedZoneId: 1
        )
        XCTAssertEqual(view.selectedZoneId, 1)
    }
}
