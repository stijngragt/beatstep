import Foundation

@MainActor
final class BPMDiscoveryService {
    static let shared = BPMDiscoveryService()

    private var discoveryPlaylistID: String? {
        get { UserDefaults.standard.string(forKey: "beatstep_discovery_playlist_id") }
        set { UserDefaults.standard.set(newValue, forKey: "beatstep_discovery_playlist_id") }
    }

    private init() {}

    // MARK: - Discover Tracks at BPM

    /// Searches GetSongBPM for songs at the target BPM, then cross-references with Spotify catalog
    func discoverTracks(atBPM bpm: Int) async throws -> [SpotifyTrack] {
        let songs = try await GetSongBPMService.shared.fetchSongsByBPM(bpm)
        var matchedTracks: [SpotifyTrack] = []

        for song in songs.prefix(10) {
            guard let title = song.title, let artistName = song.artist?.name else { continue }

            do {
                let results = try await SpotifyAPIService.shared.searchTrack(title: title, artist: artistName)
                if let track = results.first {
                    matchedTracks.append(track)
                }
            } catch {
                // Skip failed searches, continue with next song
                continue
            }

            // Rate limiting: 300ms between Spotify searches
            try await Task.sleep(nanoseconds: 300_000_000)
        }

        return matchedTracks
    }

    // MARK: - Save to Discovery Playlist

    /// Creates "BeatStep Discoveries" playlist on first call, adds tracks to it
    func saveToDiscoveryPlaylist(tracks: [SpotifyTrack]) async throws {
        if discoveryPlaylistID == nil {
            let userID = try await SpotifyAPIService.shared.fetchCurrentUserID()
            let playlist = try await SpotifyAPIService.shared.createPlaylist(
                userID: userID,
                name: "BeatStep Discoveries",
                description: "Songs discovered by BeatStep based on your running BPM"
            )
            discoveryPlaylistID = playlist.id
        }

        guard let playlistID = discoveryPlaylistID else { return }
        let uris = tracks.map(\.uri)
        try await SpotifyAPIService.shared.addTracksToPlaylist(playlistID: playlistID, uris: uris)
    }
}
