import SwiftUI
import SwiftData

struct PlaylistListView: View {
    @State private var playlists: [SpotifyPlaylist] = []
    @State private var isLoading = false
    @State private var hasMore = true
    @State private var offset = 0
    @State private var error: String?
    @State private var coverageMap: [String: String] = [:]
    @State private var coverageLoaded = false

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
            if let progress = scanService.scanProgress, scanService.scanningPlaylistID == nil {
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
                    PlaylistRow(
                        playlist: playlist,
                        coverageText: coverageMap[playlist.id],
                        coverageLoaded: coverageLoaded,
                        isScanning: scanService.scanningPlaylistID == playlist.id,
                        scanProgress: scanService.scanningPlaylistID == playlist.id ? scanService.scanProgress : nil
                    )
                }
                .swipeActions(edge: .trailing) {
                    Button {
                        Task {
                            await scanService.scanPlaylistByID(playlist.id, name: playlist.name)
                            loadCoverageData()
                        }
                    } label: {
                        Label("Analyze", systemImage: "waveform.badge.magnifyingglass")
                    }
                    .tint(Color.accent)
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
        .onChange(of: scanService.scanningPlaylistID) { oldValue, newValue in
            if oldValue != nil && newValue == nil {
                // Scan just completed, reload coverage data
                loadCoverageData()
            }
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

        let scannedMap = Dictionary(
            scannedPlaylists.map { ($0.spotifyPlaylistID, $0) },
            uniquingKeysWith: { first, _ in first }
        )

        var newCoverageMap: [String: String] = [:]
        for playlist in playlists {
            if let sp = scannedMap[playlist.id] {
                newCoverageMap[playlist.id] = "\(sp.tracksWithBPM)/\(sp.totalTracks) BPM"
            }
            // nil means "Not analyzed" -- absence from map signals unanalyzed
        }
        coverageMap = newCoverageMap
        coverageLoaded = true
    }
}

// MARK: - Playlist Row

private struct PlaylistRow: View {
    let playlist: SpotifyPlaylist
    var coverageText: String? = nil
    var coverageLoaded: Bool = false
    var isScanning: Bool = false
    var scanProgress: ScanProgress? = nil

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
                    if let count = playlist.trackCount {
                        Text("\(count) tracks")
                            .font(.captionText)
                            .foregroundStyle(Color.textSecondary)
                    }

                    if isScanning, let progress = scanProgress {
                        Text("\u{00B7}")
                            .font(.captionText)
                            .foregroundStyle(Color.textSecondary)
                        HStack(spacing: Spacing.xs) {
                            ProgressView()
                                .scaleEffect(0.7)
                            Text("Analyzing \(progress.scanned)/\(progress.total)")
                                .font(.captionText)
                                .foregroundStyle(Color.textSecondary)
                        }
                    } else if let coverageText {
                        Text("\u{00B7}")
                            .font(.captionText)
                            .foregroundStyle(Color.textSecondary)
                        Text(coverageText)
                            .font(.captionText)
                            .foregroundStyle(Color.accent)
                    } else if coverageLoaded {
                        Text("\u{00B7}")
                            .font(.captionText)
                            .foregroundStyle(Color.textSecondary)
                        Text("Not analyzed")
                            .font(.captionText)
                            .foregroundStyle(Color.stateWarning)
                    }
                }
            }
        }
        .frame(height: 50)
    }
}
