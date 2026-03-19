import SwiftUI

struct PlaylistDetailView: View {
    let playlist: SpotifyPlaylist

    @State private var tracks: [SpotifyTrack] = []
    @State private var isLoading = false
    @State private var hasMore = true
    @State private var offset = 0
    @State private var error: String?

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
                    isPlaying: playerService.currentTrack?.uri == track.uri
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    SpotifyPlayerService.shared.play(uri: track.uri)
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

                Text("\(playlist.tracks.total) tracks")
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
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}

// MARK: - Track Row

private struct TrackRow: View {
    let track: SpotifyTrack
    let index: Int
    let isPlaying: Bool

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
