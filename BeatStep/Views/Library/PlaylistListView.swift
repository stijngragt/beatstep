import SwiftUI
import SwiftData

struct PlaylistListView: View {
    @State private var playlists: [SpotifyPlaylist] = []
    @State private var isLoading = false
    @State private var hasMore = true
    @State private var offset = 0
    @State private var error: String?
    @State private var coverageMap: [String: String] = [:]

    private let limit = 50
    private var scanService: LibraryScanService { .shared }

    var body: some View {
        Group {
            if isLoading && playlists.isEmpty {
                ProgressView("Loading playlists...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error, playlists.isEmpty {
                errorView(message: error)
            } else {
                playlistList
            }
        }
        .navigationTitle("Your Library")
        .task {
            if playlists.isEmpty {
                await loadPlaylists()
            }
            loadCoverageData()
        }
        .refreshable {
            await refresh()
            loadCoverageData()
        }
    }

    // MARK: - Subviews

    private var playlistList: some View {
        List {
            // Scan progress banner
            if let progress = scanService.scanProgress {
                HStack(spacing: Spacing.sm) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Scanning BPM data... \(progress.scanned)/\(progress.total)")
                        .font(.captionText)
                        .foregroundStyle(Color.textSecondary)
                }
                .listRowSeparator(.hidden)
            }

            ForEach(playlists) { playlist in
                NavigationLink(value: playlist) {
                    PlaylistRow(playlist: playlist, coverageText: coverageMap[playlist.id])
                }
                .onAppear {
                    if playlist.id == playlists.last?.id && hasMore && !isLoading {
                        Task { await loadPlaylists() }
                    }
                }
            }

            if isLoading && !playlists.isEmpty {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .navigationDestination(for: SpotifyPlaylist.self) { playlist in
            PlaylistDetailView(playlist: playlist)
        }
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
                Task { await loadPlaylists() }
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Data Loading

    private func loadPlaylists() async {
        isLoading = true
        error = nil

        do {
            let response = try await SpotifyAPIService.shared.fetchPlaylists(offset: offset, limit: limit)
            playlists.append(contentsOf: response.items)
            hasMore = response.hasMore
            offset = response.nextOffset
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    private func refresh() async {
        playlists = []
        offset = 0
        hasMore = true
        await loadPlaylists()
    }

    private func loadCoverageData() {
        let context = BPMCacheService.shared.context
        let descriptor = FetchDescriptor<ScannedPlaylist>()
        guard let scannedPlaylists = try? context.fetch(descriptor) else { return }
        for sp in scannedPlaylists where sp.tracksWithBPM > 0 {
            coverageMap[sp.spotifyPlaylistID] = sp.coverageText
        }
    }
}

// MARK: - Playlist Row

private struct PlaylistRow: View {
    let playlist: SpotifyPlaylist
    var coverageText: String? = nil

    var body: some View {
        HStack(spacing: Spacing.md) {
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
                .frame(width: ComponentSize.coverArtSmall, height: ComponentSize.coverArtSmall)
                .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
            } else {
                RoundedRectangle(cornerRadius: Radius.sm)
                    .fill(Color.surfaceOverlay)
                    .frame(width: ComponentSize.coverArtSmall, height: ComponentSize.coverArtSmall)
                    .overlay {
                        Image(systemName: "music.note.list")
                            .foregroundStyle(Color.textTertiary)
                    }
            }

            // Text
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(playlist.name)
                    .font(.bodyText)
                    .fontWeight(.semibold)
                    .lineLimit(1)

                HStack(spacing: Spacing.xs) {
                    Text("\(playlist.trackCount) tracks")
                        .font(.captionText)
                        .foregroundStyle(Color.textSecondary)

                    if let coverageText {
                        Text("\u{00B7}")
                            .font(.captionText)
                            .foregroundStyle(Color.textSecondary)
                        Text(coverageText)
                            .font(.captionText)
                            .foregroundStyle(Color.stateWarning)
                    }
                }
            }
        }
        .frame(height: 50)
    }
}
