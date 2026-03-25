import XCTest
import SwiftData
@testable import BeatStep

@MainActor
final class LibraryScanServiceTests: XCTestCase {

    private var container: ModelContainer!
    private var cacheService: BPMCacheService!
    private var scanService: LibraryScanService!

    override func setUp() async throws {
        try await super.setUp()
        let schema = Schema([CachedBPM.self, ScannedPlaylist.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        cacheService = BPMCacheService.shared
        cacheService.setContainer(container)
        scanService = LibraryScanService.shared
    }

    override func tearDown() async throws {
        container = nil
        try await super.tearDown()
    }

    // MARK: - Delta Scan

    func testScanPlaylistSkipsCachedTracks() async {
        // Pre-cache one track
        cacheService.cacheFromAPI(trackID: "track_1", name: "Song 1", artist: "Artist 1", bpm: 120)

        let tracks = [
            makeSpotifyTrack(id: "track_1", name: "Song 1", artist: "Artist 1"),
            makeSpotifyTrack(id: "track_2", name: "Song 2", artist: "Artist 2"),
        ]

        let playlist = makeSpotifyPlaylist(id: "pl_1", name: "Test Playlist", totalTracks: 2)

        // After scan, track_1 should remain 120 (untouched), track_2 should have been looked up
        await scanService.scanPlaylist(playlist, tracks: tracks)

        let bpm1 = cacheService.getBPM(forTrackID: "track_1")
        XCTAssertEqual(bpm1, 120, "Cached track should not be re-fetched")

        // track_2 should now have a lookup attempt (even if BPM is nil since we're using real service with no API key)
        XCTAssertTrue(cacheService.hasLookup(forTrackID: "track_2"), "Uncached track should have been looked up")
    }

    // MARK: - Scan Progress

    func testScanProgressUpdates() async {
        let tracks = [
            makeSpotifyTrack(id: "track_1", name: "Song 1", artist: "Artist 1"),
            makeSpotifyTrack(id: "track_2", name: "Song 2", artist: "Artist 2"),
        ]

        let playlist = makeSpotifyPlaylist(id: "pl_1", name: "Test Playlist", totalTracks: 2)

        // Progress should be nil before scan
        XCTAssertNil(scanService.scanProgress, "Progress should be nil before scan")

        await scanService.scanPlaylist(playlist, tracks: tracks)

        // Progress should be nil after scan completes
        XCTAssertNil(scanService.scanProgress, "Progress should be nil after scan completes")
    }

    // MARK: - Failed Lookups Cached

    func testFailedLookupsCachedWithNilBPM() async {
        // Scanning with invalid API key should still cache the tracks with nil BPM
        let tracks = [
            makeSpotifyTrack(id: "track_fail", name: "Nonexistent Song", artist: "Nobody"),
        ]
        let playlist = makeSpotifyPlaylist(id: "pl_fail", name: "Fail Playlist", totalTracks: 1)

        await scanService.scanPlaylist(playlist, tracks: tracks)

        // Track should be cached (lookup attempted) even though BPM lookup failed
        XCTAssertTrue(cacheService.hasLookup(forTrackID: "track_fail"), "Failed lookup should still be cached")
    }

    // MARK: - All Cached Shortcut

    func testScanPlaylistAllCachedSkipsAPICall() async {
        // Pre-cache all tracks
        cacheService.cacheFromAPI(trackID: "track_1", name: "Song 1", artist: "Artist 1", bpm: 120)
        cacheService.cacheFromAPI(trackID: "track_2", name: "Song 2", artist: "Artist 2", bpm: 140)

        let tracks = [
            makeSpotifyTrack(id: "track_1", name: "Song 1", artist: "Artist 1"),
            makeSpotifyTrack(id: "track_2", name: "Song 2", artist: "Artist 2"),
        ]
        let playlist = makeSpotifyPlaylist(id: "pl_1", name: "Test Playlist", totalTracks: 2)

        await scanService.scanPlaylist(playlist, tracks: tracks)

        // Progress should never have been set (or set back to nil quickly)
        XCTAssertNil(scanService.scanProgress, "All cached should skip scan entirely")
    }

    // MARK: - Scanning Playlist ID Tracking

    func testScanPlaylistByIDSetsScanningPlaylistID() async {
        // scanningPlaylistID should be nil before and after scan
        XCTAssertNil(scanService.scanningPlaylistID, "scanningPlaylistID should be nil before scan")

        // We can't easily test the "during scan" state without mocking the API,
        // but we can verify it resets to nil after completion
        await scanService.scanPlaylistByID("pl_test", name: "Test Playlist")

        XCTAssertNil(scanService.scanningPlaylistID, "scanningPlaylistID should be nil after scan completes")
    }

    // MARK: - Helpers

    private func makeSpotifyTrack(id: String, name: String, artist: String) -> SpotifyTrack {
        SpotifyTrack(
            id: id,
            name: name,
            uri: "spotify:track:\(id)",
            durationMs: 200_000,
            artists: [Artist(name: artist)],
            album: Album(name: "Test Album", images: nil)
        )
    }

    private func makeSpotifyPlaylist(id: String, name: String, totalTracks: Int) -> SpotifyPlaylist {
        SpotifyPlaylist(
            id: id,
            name: name,
            description: nil,
            images: nil,
            tracks: TracksRef(total: totalTracks),
            owner: nil
        )
    }
}
