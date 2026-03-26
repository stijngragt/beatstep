import SwiftUI
import SwiftData

// MARK: - Data Types

struct PlaylistCoverage {
    let tracksWithBPM: Int
    let totalTracks: Int

    var percentage: Double {
        guard totalTracks > 0 else { return 0 }
        return Double(tracksWithBPM) / Double(totalTracks)
    }

    var statusColor: Color {
        switch percentage {
        case 0.8...: return .stateSuccess
        case 0.4...: return .stateWarning
        default:     return .stateError
        }
    }

    var text: String { "\(tracksWithBPM)/\(totalTracks) BPM" }
}

enum PlaylistFilter: String, CaseIterable {
    case all = "All"
    case analyzed = "Analyzed"
    case unanalyzed = "Unanalyzed"
}

// MARK: - PlaylistListView

struct PlaylistListView: View {
    @Environment(\.selectedTab) private var selectedTab
    @State private var playlists: [SpotifyPlaylist] = []
    @State private var isLoading = false
    @State private var hasMore = true
    @State private var offset = 0
    @State private var error: String?
    @State private var coverageData: [String: PlaylistCoverage] = [:]
    @State private var coverageLoaded = false
    @State private var searchText = ""
    @State private var activeFilter: PlaylistFilter = .all

    private let limit = 50
    private var scanService: LibraryScanService { .shared }

    private var filteredPlaylists: [SpotifyPlaylist] {
        var result = playlists

        switch activeFilter {
        case .all: break
        case .analyzed:
            result = result.filter { coverageData[$0.id] != nil }
        case .unanalyzed:
            result = result.filter { coverageData[$0.id] == nil }
        }

        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }

        return result
    }

    var body: some View {
        Group {
            if isLoading && playlists.isEmpty {
                PlaylistListSkeleton()
            } else if let error, playlists.isEmpty {
                errorView(message: error)
            } else {
                playlistList
            }
        }
        .animation(BSAnimation.smooth, value: isLoading)
        .searchable(text: $searchText, prompt: "Search playlists")
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
            // Filter chips
            FilterChipRow(activeFilter: $activeFilter)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: Spacing.xs, leading: Spacing.md, bottom: Spacing.xs, trailing: Spacing.md))

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

            if filteredPlaylists.isEmpty && !playlists.isEmpty {
                Text("No playlists match your search")
                    .font(.captionText)
                    .foregroundStyle(Color.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, Spacing.xl)
                    .listRowSeparator(.hidden)
            }

            ForEach(filteredPlaylists) { playlist in
                let coverage = coverageData[playlist.id]
                NavigationLink(value: playlist) {
                    PlaylistRow(
                        playlist: playlist,
                        coverage: coverage,
                        coverageLoaded: coverageLoaded,
                        isScanning: scanService.scanningPlaylistID == playlist.id,
                        scanProgress: scanService.scanningPlaylistID == playlist.id ? scanService.scanProgress : nil
                    )
                }
                .swipeActions(edge: .trailing) {
                    Button {
                        BSHaptics.medium()
                        Task {
                            await scanService.scanPlaylistByID(playlist.id, name: playlist.name)
                            loadCoverageData()
                        }
                    } label: {
                        Label(coverage != nil ? "Re-scan" : "Analyze", systemImage: "waveform.badge.magnifyingglass")
                    }
                    .tint(Color.accent)
                }
                .contextMenu {
                    if coverage != nil {
                        Button {
                            BSHaptics.medium()
                            Task {
                                await scanService.scanPlaylistByID(playlist.id, name: playlist.name)
                                loadCoverageData()
                            }
                        } label: {
                            Label("Re-scan", systemImage: "arrow.clockwise")
                        }
                        Button(role: .destructive) {
                            BSHaptics.warning()
                            scanService.deleteScan(playlistID: playlist.id)
                            loadCoverageData()
                        } label: {
                            Label("Delete Scan", systemImage: "trash")
                        }
                    } else {
                        Button {
                            BSHaptics.medium()
                            Task {
                                await scanService.scanPlaylistByID(playlist.id, name: playlist.name)
                                loadCoverageData()
                            }
                        } label: {
                            Label("Analyze BPM", systemImage: "waveform.badge.magnifyingglass")
                        }
                    }
                    Button {
                        selectedTab.wrappedValue = .run
                    } label: {
                        Label("Select for Run", systemImage: "figure.run")
                    }
                }
                .onAppear {
                    // Pagination trigger uses unfiltered playlists.last to avoid mismatch
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

        var newCoverageData: [String: PlaylistCoverage] = [:]
        for playlist in playlists {
            if let sp = scannedMap[playlist.id] {
                newCoverageData[playlist.id] = PlaylistCoverage(
                    tracksWithBPM: sp.tracksWithBPM,
                    totalTracks: sp.totalTracks
                )
            }
        }
        coverageData = newCoverageData
        coverageLoaded = true
    }
}

// MARK: - Filter Chip Row

private struct FilterChipRow: View {
    @Binding var activeFilter: PlaylistFilter

    var body: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(PlaylistFilter.allCases, id: \.self) { filter in
                Button {
                    BSHaptics.selection()
                    withAnimation(BSAnimation.snappy) {
                        activeFilter = filter
                    }
                } label: {
                    Text(filter.rawValue)
                        .font(.captionBold)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.xs)
                        .background(
                            activeFilter == filter ? Color.accent : Color.surfaceOverlay,
                            in: Capsule()
                        )
                        .foregroundStyle(
                            activeFilter == filter ? Color.textOnAccent : Color.textSecondary
                        )
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }
}

// MARK: - Coverage Bar

private struct CoverageBar: View {
    let coverage: PlaylistCoverage

    var body: some View {
        HStack(spacing: Spacing.sm) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.surfaceOverlay)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(coverage.statusColor)
                        .frame(width: geometry.size.width * coverage.percentage)
                }
            }
            .frame(height: 4)

            Text(coverage.text)
                .font(.captionText)
                .foregroundStyle(Color.textSecondary)
        }
    }
}

// MARK: - Playlist Row

private struct PlaylistRow: View {
    let playlist: SpotifyPlaylist
    var coverage: PlaylistCoverage? = nil
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
                .frame(width: ComponentSize.coverArtMedium, height: ComponentSize.coverArtMedium)
                .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
            } else {
                RoundedRectangle(cornerRadius: Radius.sm)
                    .fill(Color.surfaceOverlay)
                    .frame(width: ComponentSize.coverArtMedium, height: ComponentSize.coverArtMedium)
                    .overlay {
                        Image(systemName: "music.note.list")
                            .foregroundStyle(Color.textTertiary)
                    }
            }

            // Text + Coverage
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(playlist.name)
                    .font(.bodyText)
                    .fontWeight(.semibold)
                    .lineLimit(1)

                if let count = playlist.trackCount {
                    Text("\(count) tracks")
                        .font(.captionText)
                        .foregroundStyle(Color.textSecondary)
                }

                if isScanning, let progress = scanProgress {
                    HStack(spacing: Spacing.xs) {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("Analyzing \(progress.scanned)/\(progress.total)")
                            .font(.captionText)
                            .foregroundStyle(Color.textSecondary)
                    }
                } else if let coverage {
                    CoverageBar(coverage: coverage)
                } else if coverageLoaded {
                    Text("Not analyzed")
                        .font(.captionText)
                        .foregroundStyle(Color.textTertiary)
                }
            }
        }
        .frame(height: 70)
    }
}
