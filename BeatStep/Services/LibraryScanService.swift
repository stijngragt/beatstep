import Foundation
import SwiftData

struct ScanProgress {
    let playlistName: String
    var scanned: Int
    let total: Int

    var isComplete: Bool {
        scanned >= total
    }
}

@MainActor
@Observable
final class LibraryScanService {
    static let shared = LibraryScanService()

    var scanningPlaylistID: String?
    var scanProgress: ScanProgress?
    var scanCompletionCount: Int = 0

    private init() {}

    // MARK: - Scan Single Playlist

    func scanPlaylist(_ playlist: SpotifyPlaylist, tracks: [SpotifyTrack]) async {
        // Delta scan: filter to only uncached tracks
        let uncachedTracks = tracks.filter { !BPMCacheService.shared.hasLookup(forTrackID: $0.id) }

        // Update ScannedPlaylist coverage even if all cached
        updateScannedPlaylist(playlistID: playlist.id, name: playlist.name, totalTracks: tracks.count)

        debugPrint("SCAN: \(tracks.count) total, \(uncachedTracks.count) uncached")

        if uncachedTracks.isEmpty {
            debugPrint("SCAN: All cached, skipping")
            return
        }

        scanProgress = ScanProgress(playlistName: playlist.name, scanned: 0, total: uncachedTracks.count)

        // Per-track BPM lookup via GetSongBPM proxy
        for track in uncachedTracks {
            debugPrint("SCAN: Looking up '\(track.name)' by '\(track.artistName)'...")
            do {
                let bpm = try await GetSongBPMService.shared.fetchBPM(
                    title: track.name,
                    artist: track.artistName
                )
                debugPrint("SCAN: '\(track.name)' → \(bpm.map { "\($0) BPM" } ?? "no match")")
                BPMCacheService.shared.cacheFromAPI(
                    trackID: track.id,
                    name: track.name,
                    artist: track.artistName,
                    bpm: bpm
                )
            } catch {
                debugPrint("SCAN: '\(track.name)' → ERROR: \(error)")
                // Network/API error for this track -- mark as attempted with nil
                // so delta scan doesn't retry immediately
                BPMCacheService.shared.cacheFromAPI(
                    trackID: track.id,
                    name: track.name,
                    artist: track.artistName,
                    bpm: nil
                )
            }
            scanProgress?.scanned += 1
        }

        // Update ScannedPlaylist with final coverage
        let allTrackIDs = tracks.map(\.id)
        let stats = BPMCacheService.shared.coverageStats(forTrackIDs: allTrackIDs)
        updateScannedPlaylistCoverage(playlistID: playlist.id, tracksWithBPM: stats.withBPM)

        scanProgress = nil
    }

    // MARK: - Scan Playlist by ID

    func scanPlaylistByID(_ playlistID: String, name: String) async {
        // Prevent duplicate concurrent scans of the same playlist
        guard scanningPlaylistID != playlistID else { return }

        scanningPlaylistID = playlistID
        do {
            // Load all tracks for this playlist
            var allTracks: [SpotifyTrack] = []
            var offset = 0
            var hasMore = true

            while hasMore {
                let response = try await SpotifyAPIService.shared.fetchPlaylistTracks(
                    playlistID: playlistID,
                    offset: offset,
                    limit: 100
                )
                let tracks = response.items.compactMap(\.track)
                allTracks.append(contentsOf: tracks)
                hasMore = response.hasMore
                offset = response.nextOffset
            }

            let playlist = SpotifyPlaylist(
                id: playlistID,
                name: name,
                description: nil,
                images: nil,
                tracks: TracksRef(total: allTracks.count),
                owner: nil
            )
            await scanPlaylist(playlist, tracks: allTracks)
        } catch {
            debugPrint("SCAN: Failed to scan playlist \(playlistID): \(error)")
        }
        scanCompletionCount += 1
        scanningPlaylistID = nil
    }

    // MARK: - Scan All Enabled Playlists

    func scanEnabledPlaylists() async {
        let context = BPMCacheService.shared.context

        let descriptor = FetchDescriptor<ScannedPlaylist>(
            predicate: #Predicate { $0.isEnabled }
        )
        guard let enabledPlaylists = try? context.fetch(descriptor), !enabledPlaylists.isEmpty else {
            return
        }

        for scannedPlaylist in enabledPlaylists {
            await scanPlaylistByID(scannedPlaylist.spotifyPlaylistID, name: scannedPlaylist.name)
        }
    }

    // MARK: - Delete Scan

    func deleteScan(playlistID: String) {
        let context = BPMCacheService.shared.context
        let descriptor = FetchDescriptor<ScannedPlaylist>(
            predicate: #Predicate { $0.spotifyPlaylistID == playlistID }
        )
        guard let existing = try? context.fetch(descriptor).first else { return }
        context.delete(existing)
        try? context.save()
    }

    // MARK: - ScannedPlaylist Updates

    private func updateScannedPlaylist(playlistID: String, name: String, totalTracks: Int) {
        let context = BPMCacheService.shared.context
        let descriptor = FetchDescriptor<ScannedPlaylist>(
            predicate: #Predicate { $0.spotifyPlaylistID == playlistID }
        )
        if let existing = try? context.fetch(descriptor).first {
            existing.totalTracks = totalTracks
            existing.lastScanned = Date()
        } else {
            let newRecord = ScannedPlaylist(
                spotifyPlaylistID: playlistID,
                name: name,
                totalTracks: totalTracks
            )
            newRecord.lastScanned = Date()
            context.insert(newRecord)
        }
        try? context.save()
    }

    private func updateScannedPlaylistCoverage(playlistID: String, tracksWithBPM: Int) {
        let context = BPMCacheService.shared.context
        let descriptor = FetchDescriptor<ScannedPlaylist>(
            predicate: #Predicate { $0.spotifyPlaylistID == playlistID }
        )
        if let existing = try? context.fetch(descriptor).first {
            existing.tracksWithBPM = tracksWithBPM
            existing.lastScanned = Date()
        }
        try? context.save()
    }
}
