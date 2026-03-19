import XCTest
@testable import BeatStep

final class SpotifyAPIServiceTests: XCTestCase {

    // MARK: - Playlist Decoding

    func testPlaylistDecoding() throws {
        let data = MockSpotifyResponses.playlistList.data(using: .utf8)!
        let response = try JSONDecoder().decode(PaginatedResponse<SpotifyPlaylist>.self, from: data)

        XCTAssertEqual(response.items.count, 3)

        let first = response.items[0]
        XCTAssertEqual(first.name, "Running Hits")
        XCTAssertEqual(first.tracks.total, 50)
        XCTAssertEqual(first.images?.first?.url, "https://example.com/playlist1.jpg")
    }

    // MARK: - Track Decoding

    func testPlaylistTrackDecoding() throws {
        let data = MockSpotifyResponses.playlistTracks.data(using: .utf8)!
        let response = try JSONDecoder().decode(PaginatedResponse<PlaylistTrackItem>.self, from: data)

        let track = try XCTUnwrap(response.items[0].track)
        XCTAssertEqual(track.name, "Run Boy Run")
        XCTAssertEqual(track.artistName, "Woodkid")
        XCTAssertEqual(track.album.name, "The Golden Age")
        XCTAssertEqual(track.uri, "spotify:track:track_1")
    }

    // MARK: - Paginated Response

    func testPaginatedResponseDecoding() throws {
        let data = MockSpotifyResponses.playlistList.data(using: .utf8)!
        let response = try JSONDecoder().decode(PaginatedResponse<SpotifyPlaylist>.self, from: data)

        XCTAssertEqual(response.total, 3)
        XCTAssertEqual(response.offset, 0)
        XCTAssertEqual(response.limit, 50)
        XCTAssertNil(response.next)
        XCTAssertFalse(response.hasMore)
        XCTAssertEqual(response.nextOffset, 50)
    }

    // MARK: - Empty Response

    func testEmptyPlaylistResponse() throws {
        let json = """
        {
            "items": [],
            "total": 0,
            "limit": 50,
            "offset": 0,
            "next": null
        }
        """
        let data = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(PaginatedResponse<SpotifyPlaylist>.self, from: data)

        XCTAssertTrue(response.items.isEmpty)
        XCTAssertEqual(response.total, 0)
        XCTAssertFalse(response.hasMore)
    }

    // MARK: - Error Handling

    func testErrorResponseHandling() throws {
        // Verify we can detect a 401 pattern from Spotify's error JSON
        let data = MockSpotifyResponses.unauthorizedError.data(using: .utf8)!

        struct SpotifyErrorResponse: Decodable {
            let error: ErrorDetail
            struct ErrorDetail: Decodable {
                let status: Int
                let message: String
            }
        }

        let errorResponse = try JSONDecoder().decode(SpotifyErrorResponse.self, from: data)
        XCTAssertEqual(errorResponse.error.status, 401)
        XCTAssertEqual(errorResponse.error.message, "The access token expired")
    }
}
