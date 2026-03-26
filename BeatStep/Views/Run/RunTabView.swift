import SwiftUI

struct RunTabView: View {
    @Binding var selectedTab: Tab

    @State private var playlist: SpotifyPlaylist?
    @State private var tracks: [SpotifyTrack] = []
    @State private var isLoading = false
    @State private var loadError: String?
    @State private var showActiveRun = false
    @State private var selectedZoneIds: Set<Int> = RunZone.selectedZoneIds
    @State private var tolerance: BPMTolerance = .saved
    @State private var lastFetchedPlaylistId: String?

    private var cadenceService: CadenceService { .shared }
    private var runEngine: RunEngineService { .shared }

    private var canStartRun: Bool {
        playlist != nil && !tracks.isEmpty && !isLoading
    }

    var body: some View {
        ZStack {
            Color.surfaceBase.ignoresSafeArea()

            if LastRunPlaylist.id == nil {
                noPlaylistContent
            } else if isLoading && playlist == nil {
                loadingContent
            } else if let playlist {
                loadedContent(playlist: playlist)
            } else if loadError != nil {
                errorOnlyContent
            } else {
                loadingContent
            }
        }
        .navigationTitle("Run")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            selectedZoneIds = RunZone.selectedZoneIds
            tolerance = .saved
            fetchPlaylistIfNeeded()
        }
        .onChange(of: selectedZoneIds) { _, newValue in
            RunZone.selectedZoneIds = newValue
            if !newValue.isEmpty {
                let zones = RunZone.saved.filter { newValue.contains($0.id) }
                let floor = zones.map(\.bpm).min() ?? 160
                let ceiling = zones.map(\.bpm).max() ?? 160
                let midpoint = (floor + ceiling) / 2
                RunMode.savedTargetBPM = midpoint
                RunMode.guided.save()
            } else {
                RunMode.free.save()
            }
        }
        .fullScreenCover(isPresented: $showActiveRun) {
            if let playlist {
                ActiveRunView(playlist: playlist, tracks: tracks, selectedZoneIds: selectedZoneIds)
                    .interactiveDismissDisabled(true)
            }
        }
        .onDisappear {
            if !runEngine.isRunActive {
                runEngine.stopRun()
                UIApplication.shared.isIdleTimerDisabled = false
                cadenceService.stopDetecting()
            }
        }
        .animation(BSAnimation.snappy, value: selectedZoneIds)
    }

    // MARK: - No Playlist State

    private var noPlaylistContent: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: Spacing.lg) {
                Text("Pick a playlist to get started")
                    .font(.captionText)
                    .foregroundStyle(Color.textSecondary)

                Button {
                    BSHaptics.light()
                    selectedTab = .library
                } label: {
                    Text("Go to Library")
                        .font(.bodyBold)
                        .foregroundStyle(Color.accent)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.sm)
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.lg)
                                .stroke(Color.accent, lineWidth: 1.5)
                        )
                }
            }

            Spacer()

            startRunButton
        }
    }

    // MARK: - Loading State

    private var loadingContent: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: Spacing.md) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(Color.textSecondary)

                Text("Loading playlist...")
                    .font(.captionText)
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer()

            startRunButton
        }
    }

    // MARK: - Error-Only State (no cached playlist)

    private var errorOnlyContent: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: Spacing.md) {
                Text(loadError ?? "Something went wrong")
                    .font(.captionText)
                    .foregroundStyle(Color.textSecondary)

                Button {
                    BSHaptics.light()
                    fetchPlaylistIfNeeded(force: true)
                } label: {
                    Text("Retry")
                        .font(.bodyBold)
                        .foregroundStyle(Color.accent)
                }
                .buttonStyle(.borderless)
            }

            Spacer()

            startRunButton
        }
    }

    // MARK: - Loaded State

    private func loadedContent(playlist: SpotifyPlaylist) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Tappable playlist row
                    Button {
                        selectedTab = .library
                    } label: {
                        VStack(spacing: Spacing.lg) {
                            // Cover art
                            if let imageURLString = playlist.images?.first?.url,
                               let imageURL = URL(string: imageURLString) {
                                AsyncImage(url: imageURL) { phase in
                                    switch phase {
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    case .failure:
                                        coverArtPlaceholder
                                    case .empty:
                                        coverArtPlaceholder
                                    @unknown default:
                                        coverArtPlaceholder
                                    }
                                }
                                .frame(width: ComponentSize.coverArtLarge, height: ComponentSize.coverArtLarge)
                                .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                            } else {
                                coverArtPlaceholder
                            }

                            // Playlist name
                            Text(playlist.name)
                                .font(.heading)
                                .foregroundStyle(Color.textPrimary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, Spacing.xl)

                            // Subtitle
                            Text("Your last playlist")
                                .font(.captionText)
                                .foregroundStyle(Color.textSecondary)
                        }
                    }
                    .buttonStyle(.plain)

                    // Error banner (if fetch partially failed on re-fetch)
                    if let loadError {
                        VStack(spacing: Spacing.sm) {
                            Text(loadError)
                                .font(.captionText)
                                .foregroundStyle(Color.textSecondary)

                            Button {
                                BSHaptics.light()
                                fetchPlaylistIfNeeded(force: true)
                            } label: {
                                Text("Retry")
                                    .font(.bodyBold)
                                    .foregroundStyle(Color.accent)
                            }
                            .buttonStyle(.borderless)
                        }
                    }

                    // Zone picker
                    ZonePickerView(selectedZoneIds: $selectedZoneIds)

                    // Conditional tolerance picker + merged BPM range
                    if !selectedZoneIds.isEmpty {
                        TolerancePicker(tolerance: $tolerance)
                            .padding(.horizontal, Spacing.xl)
                            .transition(.opacity.combined(with: .move(edge: .top)))

                        if let range = RunZone.mergedBPMRange(for: selectedZoneIds) {
                            Text("\(range.lowerBound)-\(range.upperBound) BPM")
                                .font(.captionText)
                                .foregroundStyle(Color.textSecondary)
                        }
                    }
                }
            }

            Spacer()

            startRunButton
        }
    }

    // MARK: - Start Run Button

    private var startRunButton: some View {
        Button {
            startRun()
        } label: {
            Text("Start Run")
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.textOnAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .background(RoundedRectangle(cornerRadius: Radius.lg).fill(Color.accent))
        }
        .disabled(!canStartRun)
        .opacity(canStartRun ? 1.0 : 0.4)
        .padding(.horizontal, Spacing.xl)
        .padding(.bottom, Spacing.md)
    }

    // MARK: - Actions

    private func startRun() {
        BSHaptics.success()
        guard let playlist else { return }

        // Configure engine mode
        if !selectedZoneIds.isEmpty {
            let zones = RunZone.saved.filter { selectedZoneIds.contains($0.id) }
            let floor = zones.map(\.bpm).min() ?? 160
            let ceiling = zones.map(\.bpm).max() ?? 160
            let midpoint = (floor + ceiling) / 2
            runEngine.runMode = .guided
            runEngine.tolerance = tolerance
            RunMode.savedTargetBPM = midpoint
        } else {
            runEngine.runMode = .free
            runEngine.tolerance = tolerance
        }

        cadenceService.requestPermissionAndStart()
        UIApplication.shared.isIdleTimerDisabled = true
        showActiveRun = true
        Task { await runEngine.startRun(playlist: playlist, tracks: tracks) }
    }

    private func fetchPlaylistIfNeeded(force: Bool = false) {
        guard let playlistId = LastRunPlaylist.id else { return }
        guard force || playlistId != lastFetchedPlaylistId else { return }

        isLoading = true
        loadError = nil

        Task {
            do {
                async let fetchedPlaylist = SpotifyAPIService.shared.fetchPlaylist(id: playlistId)
                async let fetchedTracksResponse = SpotifyAPIService.shared.fetchPlaylistTracks(playlistID: playlistId)

                let playlistResult = try await fetchedPlaylist
                let tracksResult = try await fetchedTracksResponse

                playlist = playlistResult
                tracks = tracksResult.items.compactMap { $0.track }
                lastFetchedPlaylistId = playlistId
                loadError = nil
            } catch {
                // Check for 404 (playlist deleted/private)
                if case SpotifyError.apiError(let statusCode, _) = error, statusCode == 404 {
                    LastRunPlaylist.name = nil
                    LastRunPlaylist.id = nil
                    LastRunPlaylist.imageURL = nil
                } else {
                    loadError = "Couldn't load playlist"
                }
            }
            isLoading = false
        }
    }

    // MARK: - Helpers

    private var coverArtPlaceholder: some View {
        RoundedRectangle(cornerRadius: Radius.md)
            .fill(Color.surfaceOverlay)
            .frame(width: ComponentSize.coverArtLarge, height: ComponentSize.coverArtLarge)
            .overlay {
                Image(systemName: "music.note")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.textTertiary)
            }
    }
}
