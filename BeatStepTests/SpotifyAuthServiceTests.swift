import XCTest
@testable import BeatStep

final class SpotifyAuthServiceTests: XCTestCase {

    override func tearDown() {
        super.tearDown()
        KeychainManager.shared.clearAll()
    }

    // MARK: - Keychain Tests

    func testKeychainStoreAndRetrieve() {
        let testToken = "test_access_token_12345"
        KeychainManager.shared.accessToken = testToken

        let retrieved = KeychainManager.shared.accessToken
        XCTAssertEqual(retrieved, testToken, "Retrieved token should match stored token")
    }

    func testKeychainClearAll() {
        KeychainManager.shared.accessToken = "some_token"
        KeychainManager.shared.tokenExpirationDate = Date()

        KeychainManager.shared.clearAll()

        XCTAssertNil(KeychainManager.shared.accessToken, "Access token should be nil after clearAll")
        XCTAssertNil(KeychainManager.shared.tokenExpirationDate, "Expiration date should be nil after clearAll")
    }

    func testKeychainTokenExpirationDate() {
        let now = Date()
        KeychainManager.shared.tokenExpirationDate = now

        let retrieved = KeychainManager.shared.tokenExpirationDate
        XCTAssertNotNil(retrieved)
        // Allow 1 second tolerance due to TimeInterval conversion
        XCTAssertEqual(retrieved!.timeIntervalSince1970, now.timeIntervalSince1970, accuracy: 1.0)
    }

    // MARK: - User Parsing Tests

    func testPremiumUserParsing() throws {
        let data = MockSpotifyResponses.premiumUser.data(using: .utf8)!
        let user = try JSONDecoder().decode(SpotifyUser.self, from: data)

        XCTAssertEqual(user.id, "test_user_123")
        XCTAssertEqual(user.displayName, "Test Runner")
        XCTAssertEqual(user.product, "premium")
        XCTAssertTrue(user.isPremium)
        XCTAssertEqual(user.images?.count, 1)
        XCTAssertEqual(user.images?.first?.url, "https://example.com/avatar.jpg")
    }

    func testFreeUserParsing() throws {
        let data = MockSpotifyResponses.freeUser.data(using: .utf8)!
        let user = try JSONDecoder().decode(SpotifyUser.self, from: data)

        XCTAssertEqual(user.id, "free_user_456")
        XCTAssertEqual(user.displayName, "Free User")
        XCTAssertEqual(user.product, "free")
        XCTAssertFalse(user.isPremium)
    }

    // MARK: - Model Parsing Tests

    func testPlaylistParsing() throws {
        let data = MockSpotifyResponses.playlistList.data(using: .utf8)!
        let response = try JSONDecoder().decode(PaginatedResponse<SpotifyPlaylist>.self, from: data)

        XCTAssertEqual(response.items.count, 3)
        XCTAssertEqual(response.total, 3)
        XCTAssertFalse(response.hasMore)

        let first = response.items[0]
        XCTAssertEqual(first.id, "playlist_1")
        XCTAssertEqual(first.name, "Running Hits")
        XCTAssertEqual(first.tracks?.total, 50)
        XCTAssertEqual(first.owner?.displayName, "Test Runner")
    }

    func testTrackParsing() throws {
        let data = MockSpotifyResponses.playlistTracks.data(using: .utf8)!
        let response = try JSONDecoder().decode(PaginatedResponse<PlaylistTrackItem>.self, from: data)

        XCTAssertEqual(response.items.count, 4)

        let track = response.items[0].track!
        XCTAssertEqual(track.id, "track_1")
        XCTAssertEqual(track.name, "Run Boy Run")
        XCTAssertEqual(track.uri, "spotify:track:track_1")
        XCTAssertEqual(track.durationMs, 232000)
        XCTAssertEqual(track.artistName, "Woodkid")
        XCTAssertEqual(track.album.name, "The Golden Age")

        // Multi-artist track
        let multiArtistTrack = response.items[2].track!
        XCTAssertEqual(multiArtistTrack.artistName, "Eminem, Nate Dogg")
    }

    // MARK: - SpotifyError Tests

    func testSpotifyErrorCases() {
        // Verify all error cases exist and have descriptions
        let errors: [SpotifyError] = [
            .notAuthenticated,
            .tokenExpired,
            .invalidResponse,
            .premiumRequired,
            .spotifyNotInstalled,
            .networkError(NSError(domain: "test", code: 0)),
            .apiError(statusCode: 401, message: "Unauthorized")
        ]

        for error in errors {
            XCTAssertNotNil(error.errorDescription, "Error \(error) should have a description")
        }
    }
}
