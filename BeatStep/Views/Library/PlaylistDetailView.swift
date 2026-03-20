import SwiftUI

struct PlaylistDetailView: View {
    let playlist: SpotifyPlaylist

    @State private var tracks: [SpotifyTrack] = []
    @State private var isLoading = false
    @State private var hasMore = true
    @State private var offset = 0
    @State private var error: String?
    @State private var bpmCache: [String: Int?] = [:]
    @State private var isScanning = false

    private let limit = 100
    private var playerService: SpotifyPlayerService { .shared }

    var body: some View {
        Group {
            if isLoading && tracks.isEmpty {
                ProgressView("Loading tracks...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error, tracks.isEmpty {
                errorView(message: error)
            } else {
                trackList
            }
        }
        .navigationTitle(playlist.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    Task { await scanBPM() }
                } label: {
                    Label("Scan BPM", systemImage: isScanning ? "progress.indicator" : "waveform.badge.magnifyingglass")
                }
                .disabled(isScanning || tracks.isEmpty)

                Button {
                    clearBPM()
                } label: {
                    Label("Clear BPM", systemImage: "trash")
                }
                .disabled(tracks.isEmpty)
            }
        }
        .task {
            if tracks.isEmpty {
                await loadTracks()
            }
        }
    }

    // MARK: - Subviews

    private var trackList: some View {
        List {
            // Header
            playlistHeader
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 16, leading: 0, bottom: 16, trailing: 0))

            // Tracks
            ForEach(Array(tracks.enumerated()), id: \.element.id) { index, track in
                TrackRow(
                    track: track,
                    index: index + 1,
                    isPlaying: playerService.currentTrack?.uri == track.uri,
                    bpm: bpmCache[track.id].flatMap { $0 }
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    SpotifyPlayerService.shared.play(uri: track.uri, contextURI: "spotify:playlist:\(playlist.id)")
                }
                .onAppear {
                    if track.id == tracks.last?.id && hasMore && !isLoading {
                        Task { await loadTracks() }
                    }
                }
            }

            if isLoading && !tracks.isEmpty {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
    }

    private var playlistHeader: some View {
        VStack(spacing: 12) {
            // Cover art
            if let imageURL = playlist.images?.first?.url,
               let url = URL(string: imageURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(width: 200, height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 200, height: 200)
                    .overlay {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 50))
                            .foregroundStyle(.gray)
                    }
            }

            Text(playlist.name)
                .font(.title2)
                .fontWeight(.bold)

            HStack(spacing: 8) {
                if let owner = playlist.owner?.displayName {
                    Text(owner)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Text("\(playlist.trackCount) tracks")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            Text(message)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                Task { await loadTracks() }
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Data Loading

    private func loadTracks() async {
        isLoading = true
        error = nil

        do {
            let response = try await SpotifyAPIService.shared.fetchPlaylistTracks(
                playlistID: playlist.id,
                offset: offset,
                limit: limit
            )
            let newTracks = response.items.compactMap(\.track)
            tracks.append(contentsOf: newTracks)
            hasMore = response.hasMore
            offset = response.nextOffset

            // Load BPMs for new tracks from cache
            for track in newTracks {
                bpmCache[track.id] = BPMCacheService.shared.getBPM(forTrackID: track.id)
            }
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    private func scanBPM() async {
        debugPrint("SCAN: Button tapped, \(tracks.count) tracks")
        isScanning = true
        await LibraryScanService.shared.scanPlaylist(playlist, tracks: tracks)
        // Reload cache
        for track in tracks {
            bpmCache[track.id] = BPMCacheService.shared.getBPM(forTrackID: track.id)
        }
        isScanning = false
    }

    private func clearBPM() {
        for track in tracks {
            BPMCacheService.shared.clearCache(forTrackID: track.id)
            bpmCache[track.id] = nil
        }
    }
}

// MARK: - Track Row

private struct TrackRow: View {
    let track: SpotifyTrack
    let index: Int
    let isPlaying: Bool
    let bpm: Int?

    var body: some View {
        HStack(spacing: 12) {
            // Track number or playing indicator
            Group {
                if isPlaying {
                    Image(systemName: "waveform")
                        .foregroundStyle(.green)
                } else {
                    Text("\(index)")
                        .foregroundStyle(.secondary)
                }
            }
            .font(.subheadline)
            .frame(width: 28, alignment: .center)

            // Track info
            VStack(alignment: .leading, spacing: 2) {
                Text(track.name)
                    .font(.body)
                    .fontWeight(isPlaying ? .bold : .regular)
                    .foregroundStyle(isPlaying ? .green : .primary)
                    .lineLimit(1)

                Text(track.artistName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // BPM badge
            if let bpm {
                Text("\(bpm) BPM")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(.orange.opacity(0.15)))
            } else {
                Text("--")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            // Duration
            Text(formatDuration(ms: track.durationMs))
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }

    private func formatDuration(ms: Int) -> String {
        let totalSeconds = ms / 1000
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
}
