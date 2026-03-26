import SwiftUI

struct OnboardingPlaylistView: View {
    let onContinue: () -> Void

    @State private var playlists: [SpotifyPlaylist] = []
    @State private var isLoading = true
    @State private var selectedPlaylist: SpotifyPlaylist? = nil
    @State private var analysisComplete = false

    private var scanService: LibraryScanService { .shared }

    var body: some View {
        VStack(spacing: Spacing.xl) {
            if isLoading {
                loadingState
            } else if let selected = selectedPlaylist {
                analyzingState(playlist: selected)
            } else {
                pickerState
            }
        }
        .padding(.horizontal, Spacing.xl)
        .background(Color.surfaceBase)
        .task {
            await loadPlaylists()
        }
    }

    // MARK: - Loading State

    private var loadingState: some View {
        VStack(spacing: Spacing.md) {
            Spacer()
            ProgressView("Loading playlists...")
                .foregroundStyle(Color.textSecondary)
            Spacer()
        }
    }

    // MARK: - Picker State

    private var pickerState: some View {
        Group {
            Spacer()
                .frame(height: Spacing.xl)

            // Value framing
            VStack(spacing: Spacing.md) {
                Image(systemName: "music.note.list")
                    .font(.system(size: ComponentSize.iconLarge))
                    .foregroundStyle(Color.accent)

                Text("Pick Your First Playlist")
                    .font(.heading)
                    .foregroundStyle(Color.textPrimary)

                Text("Choose a playlist to analyze. BeatStep will find the BPM for each track so it can match songs to your pace.")
                    .font(.bodyText)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
            }

            // Playlist list
            ScrollView {
                LazyVStack(spacing: Spacing.xs) {
                    ForEach(playlists) { playlist in
                        Button {
                            BSHaptics.light()
                            Task {
                                await selectPlaylist(playlist)
                            }
                        } label: {
                            playlistRow(playlist)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, Spacing.sm)
            }
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))

            Spacer()
                .frame(height: Spacing.xxl)
        }
    }

    private func playlistRow(_ playlist: SpotifyPlaylist) -> some View {
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

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(playlist.name)
                    .font(.bodyText)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)

                if let count = playlist.trackCount {
                    Text("\(count) tracks")
                        .font(.captionText)
                        .foregroundStyle(Color.textSecondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.captionText)
                .foregroundStyle(Color.textTertiary)
        }
        .padding(.vertical, Spacing.sm)
        .padding(.horizontal, Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Radius.sm)
                .fill(Color.surfaceElevated)
        )
    }

    // MARK: - Analyzing State

    private func analyzingState(playlist: SpotifyPlaylist) -> some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            VStack(spacing: Spacing.md) {
                if analysisComplete {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: ComponentSize.iconLarge))
                        .foregroundStyle(Color.stateSuccess)

                    Text("Ready to Run!")
                        .font(.heading)
                        .foregroundStyle(Color.textPrimary)

                    Text("\(playlist.name) has been analyzed. BeatStep can now match these songs to your running pace.")
                        .font(.bodyText)
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.center)
                } else {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding(.bottom, Spacing.sm)

                    Text("Analyzing \(playlist.name)")
                        .font(.heading)
                        .foregroundStyle(Color.textPrimary)
                        .multilineTextAlignment(.center)

                    if let progress = scanService.scanProgress {
                        Text("Analyzing... \(progress.scanned)/\(progress.total) tracks")
                            .font(.bodyText)
                            .foregroundStyle(Color.textSecondary)
                    } else {
                        Text("Starting analysis...")
                            .font(.bodyText)
                            .foregroundStyle(Color.textSecondary)
                    }
                }
            }

            Spacer()

            if analysisComplete {
                Button {
                    BSHaptics.success()
                    onContinue()
                } label: {
                    Text("Continue")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(Color.accent)
                        .foregroundStyle(Color.textOnAccent)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.pill))
                }
            }

            Spacer()
                .frame(height: Spacing.xxl)
        }
    }

    // MARK: - Actions

    private func loadPlaylists() async {
        do {
            let response = try await SpotifyAPIService.shared.fetchPlaylists(offset: 0, limit: 20)
            playlists = response.items
        } catch {
            // On error, show empty state -- user can still proceed if needed
            playlists = []
        }
        isLoading = false
    }

    private func selectPlaylist(_ playlist: SpotifyPlaylist) async {
        selectedPlaylist = playlist
        await scanService.scanPlaylistByID(playlist.id, name: playlist.name)
        analysisComplete = true
    }
}
