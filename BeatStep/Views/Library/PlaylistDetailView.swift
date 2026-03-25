import SwiftUI

struct PlaylistDetailView: View {
    let playlist: SpotifyPlaylist

    @State private var tracks: [SpotifyTrack] = []
    @State private var isLoading = false
    @State private var hasMore = true
    @State private var offset = 0
    @State private var error: String?
    @State private var bpmCache: [String: BPMInfo] = [:]
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
                NavigationLink {
                    RunView(playlist: playlist, tracks: tracks)
                } label: {
                    Label("Run", systemImage: "figure.run")
                }

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
                .listRowInsets(EdgeInsets(top: Spacing.md, leading: 0, bottom: Spacing.md, trailing: 0))

            // Tracks
            ForEach(Array(tracks.enumerated()), id: \.element.id) { index, track in
                TrackRow(
                    track: track,
                    index: index + 1,
                    isPlaying: playerService.currentTrack?.uri == track.uri,
                    bpmInfo: bpmCache[track.id] ?? .empty
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
        VStack(spacing: Spacing.md) {
            // Cover art
            if let imageURL = playlist.images?.first?.url,
               let url = URL(string: imageURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: Radius.sm)
                        .fill(Color.surfaceOverlay)
                }
                .frame(width: ComponentSize.coverArtLarge, height: ComponentSize.coverArtLarge)
                .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
            } else {
                RoundedRectangle(cornerRadius: Radius.sm)
                    .fill(Color.surfaceOverlay)
                    .frame(width: ComponentSize.coverArtLarge, height: ComponentSize.coverArtLarge)
                    .overlay {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 50))
                            .foregroundStyle(Color.textTertiary)
                    }
            }

            Text(playlist.name)
                .font(.heading)
                .fontWeight(.bold)

            HStack(spacing: Spacing.sm) {
                if let owner = playlist.owner?.displayName {
                    Text(owner)
                        .font(.captionText)
                        .foregroundStyle(Color.textSecondary)
                }

                if let count = playlist.trackCount {
                    Text("\(count) tracks")
                        .font(.captionText)
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundStyle(Color.textSecondary)

            Text(message)
                .font(.bodyText)
                .foregroundStyle(Color.textSecondary)
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
                bpmCache[track.id] = BPMCacheService.shared.getBPMInfo(forTrackID: track.id)
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
            bpmCache[track.id] = BPMCacheService.shared.getBPMInfo(forTrackID: track.id)
        }
        isScanning = false
    }

    private func clearBPM() {
        for track in tracks {
            BPMCacheService.shared.clearCache(forTrackID: track.id)
            bpmCache[track.id] = .empty
        }
    }
}

// MARK: - Track Row

private struct TrackRow: View {
    let track: SpotifyTrack
    let index: Int
    let isPlaying: Bool
    let bpmInfo: BPMInfo

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Track number or playing indicator
            Group {
                if isPlaying {
                    Image(systemName: "waveform")
                        .foregroundStyle(Color.stateSuccess)
                } else {
                    Text("\(index)")
                        .foregroundStyle(Color.textSecondary)
                }
            }
            .font(.captionText)
            .frame(width: 28, alignment: .center)

            // Track info
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(track.name)
                    .font(.bodyText)
                    .fontWeight(isPlaying ? .bold : .regular)
                    .foregroundStyle(isPlaying ? Color.stateSuccess : Color.textPrimary)
                    .lineLimit(1)

                Text(track.artistName)
                    .font(.captionText)
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            // BPM badge
            if let bpm = bpmInfo.bpm, let confidence = bpmInfo.confidence {
                HStack(spacing: Spacing.xxs) {
                    Image(systemName: confidence.iconName)
                    Text("\(bpm) BPM")
                }
                .font(.labelText)
                .fontWeight(.bold)
                .foregroundStyle(confidence.color)
                .padding(.horizontal, 6)
                .padding(.vertical, Spacing.xxs)
                .background(Capsule().fill(confidence.color.opacity(0.15)))
            } else {
                Text("-- BPM")
                    .font(.labelText)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.textTertiary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, Spacing.xxs)
                    .background(Capsule().fill(Color.textTertiary.opacity(0.15)))
            }

            // Duration
            Text(formatDuration(ms: track.durationMs))
                .font(.captionText)
                .foregroundStyle(Color.textSecondary)
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
