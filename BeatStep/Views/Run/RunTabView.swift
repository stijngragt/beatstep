import SwiftUI

struct RunTabView: View {
    @State private var lastPlaylistName: String?
    @State private var lastPlaylistImageURL: String?
    @State private var selectedZoneId: Int? = RunZone.selectedZoneId
    @State private var tolerance: BPMTolerance = .saved

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
            selectedZoneId = RunZone.selectedZoneId
        }
        .onChange(of: selectedZoneId) { _, newValue in
            RunZone.selectedZoneId = newValue
            if let zoneId = newValue,
               let zone = RunZone.saved.first(where: { $0.id == zoneId }) {
                RunMode.savedTargetBPM = zone.bpm
                RunMode.guided.save()
            } else {
                RunMode.free.save()
            }
        }
    }

    // MARK: - Has Previous Run

    private func lastRunContent(name: String) -> some View {
        VStack(spacing: 0) {
            // Scrollable content area
            ScrollView {
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

                    // Zone picker
                    ZonePickerView(selectedZoneId: $selectedZoneId)

                    // Conditional tolerance picker
                    if selectedZoneId != nil {
                        TolerancePicker(tolerance: $tolerance)
                            .padding(.horizontal, Spacing.xl)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }

            Spacer()

            // Full-width pinned CTA
            Button {
                // RunView stays in Library tab's NavigationStack
                RunZone.selectedZoneId = selectedZoneId
            } label: {
                Text("Start Run")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.textOnAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(RoundedRectangle(cornerRadius: Radius.lg).fill(Color.accent))
            }
            .padding(.horizontal, Spacing.xl)
            .padding(.bottom, Spacing.md)
        }
        .animation(.easeInOut(duration: 0.2), value: selectedZoneId)
    }

    // MARK: - No Previous Run

    private var noRunContent: some View {
        Text("Select a playlist from Library to start")
            .font(.captionText)
            .foregroundStyle(Color.textSecondary)
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
