import XCTest
import SwiftData
@testable import BeatStep

final class ModelDecodingTests: XCTestCase {

    private let decoder = JSONDecoder()

    // MARK: - GetSongBPM Search Response

    func testSearchResponseDecoding() throws {
        let response = try decoder.decode(GetSongBPMSearchResponse.self, from: MockGetSongBPMResponses.searchSuccess)
        XCTAssertEqual(response.search.count, 2)
        XCTAssertEqual(response.search[0].id, "abc123")
        XCTAssertEqual(response.search[0].title, "Run Boy Run")
        XCTAssertEqual(response.search[0].artist?.name, "Woodkid")
    }

    func testSearchResponseEmptyDecoding() throws {
        let response = try decoder.decode(GetSongBPMSearchResponse.self, from: MockGetSongBPMResponses.searchEmpty)
        XCTAssertTrue(response.search.isEmpty)
    }

    // MARK: - GetSongBPM Song Response

    func testSongResponseDecoding() throws {
        let response = try decoder.decode(GetSongBPMSongResponse.self, from: MockGetSongBPMResponses.songSuccess)
        XCTAssertEqual(response.song.tempo, "172")
        XCTAssertEqual(response.song.title, "Run Boy Run")
        XCTAssertEqual(response.song.artist?.name, "Woodkid")
        XCTAssertEqual(response.song.album?.title, "The Golden Age")
    }

    func testSongResponseNoTempo() throws {
        let response = try decoder.decode(GetSongBPMSongResponse.self, from: MockGetSongBPMResponses.songNoTempo)
        XCTAssertTrue(response.song.tempo?.isEmpty ?? true)
    }

    // MARK: - GetSongBPM Tempo Response

    func testTempoResponseDecoding() throws {
        let response = try decoder.decode(GetSongBPMTempoResponse.self, from: MockGetSongBPMResponses.tempoSuccess)
        XCTAssertEqual(response.tempo.count, 3)
        XCTAssertEqual(response.tempo[0].title, "Fast Track")
        XCTAssertEqual(response.tempo[0].tempo, "170")
    }

    // MARK: - ScannedPlaylist Coverage Text

    func testCoverageText() {
        let playlist = ScannedPlaylist(spotifyPlaylistID: "test_id", name: "Test Playlist", totalTracks: 10, tracksWithBPM: 5)
        XCTAssertEqual(playlist.coverageText, "5 of 10 tracks have BPM")
    }

    func testCoverageTextZero() {
        let playlist = ScannedPlaylist(spotifyPlaylistID: "test_id", name: "Empty", totalTracks: 0, tracksWithBPM: 0)
        XCTAssertEqual(playlist.coverageText, "0 of 0 tracks have BPM")
    }
}
