import XCTest
@testable import BeatStep

final class TrackCountTests: XCTestCase {

    // MARK: - trackCount optionality

    func testTrackCountNilWhenTracksObjectMissing() {
        let playlist = SpotifyPlaylist(
            id: "discover-weekly",
            name: "Discover Weekly",
            description: nil,
            images: nil,
            tracks: nil,
            owner: nil
        )
        XCTAssertNil(playlist.trackCount, "trackCount should be nil when tracks object is missing")
    }

    func testTrackCountZeroWhenExplicitlyEmpty() {
        let playlist = SpotifyPlaylist(
            id: "empty-playlist",
            name: "Empty",
            description: nil,
            images: nil,
            tracks: TracksRef(total: 0),
            owner: nil
        )
        XCTAssertEqual(playlist.trackCount, 0, "trackCount should be 0 when tracks.total is 0")
    }

    func testTrackCountReturnsActualValue() {
        let playlist = SpotifyPlaylist(
            id: "my-playlist",
            name: "Running Mix",
            description: nil,
            images: nil,
            tracks: TracksRef(total: 42),
            owner: nil
        )
        XCTAssertEqual(playlist.trackCount, 42, "trackCount should return the actual total")
    }
}
