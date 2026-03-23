import SwiftUI

struct RunTabView: View {
    @State private var lastPlaylistName: String?
    @State private var lastPlaylistImageURL: String?

    var body: some View {
        ZStack {
            Color.surfaceBase.ignoresSafeArea()

            if let playlistName = lastPlaylistName {
                lastRunContent(name: playlistName)
            } else {
                noRunContent
            }
        }
        .navigationTitle("Run")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            lastPlaylistName = LastRunPlaylist.name
            lastPlaylistImageURL = LastRunPlaylist.imageURL
        }
    }

    // MARK: - Has Previous Run

    private func lastRunContent(name: String) -> some View {
        VStack(spacing: Spacing.lg) {
            // Playlist cover art
            if let imageURLString = lastPlaylistImageURL,
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
            Text(name)
                .font(.heading)
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)

            // Last run hint
            Text("Your last playlist")
                .font(.captionText)
                .foregroundStyle(Color.textSecondary)

            // Start Run button (non-functional per Phase 7 decision)
            Button {
                // RunView stays in Library tab's NavigationStack
            } label: {
                Text("Start Run")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.textOnAccent)
                    .padding(.horizontal, Spacing.xl)
                    .padding(.vertical, Spacing.md)
                    .background(Capsule().fill(Color.accent))
            }

            Text("Select a playlist from Library to start a new run")
                .font(.captionText)
                .foregroundStyle(Color.textSecondary)
        }
    }

    // MARK: - No Previous Run

    private var noRunContent: some View {
        VStack(spacing: 0) {
            Button {
                // Phase 8 (NAV-04) adds playlist context and start flow
            } label: {
                Text("Start Run")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.textOnAccent)
                    .padding(.horizontal, Spacing.xl)
                    .padding(.vertical, Spacing.md)
                    .background(Capsule().fill(Color.accent))
            }

            Text("Select a playlist from Library to start")
                .font(.captionText)
                .foregroundStyle(Color.textSecondary)
                .padding(.top, Spacing.sm)
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
