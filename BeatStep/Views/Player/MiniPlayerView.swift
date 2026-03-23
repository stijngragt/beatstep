import SwiftUI

struct MiniPlayerView: View {
    private var playerService: SpotifyPlayerService { .shared }
    @State private var currentBPM: Int?

    var body: some View {
        if let track = playerService.currentTrack {
            HStack(spacing: Spacing.md) {
                // BPM display
                VStack(spacing: 0) {
                    if let bpm = currentBPM {
                        Text("\(bpm)")
                            .font(.captionBold)
                            .foregroundStyle(Color.stateWarning)
                        Text("BPM")
                            .font(.labelText)
                            .foregroundStyle(Color.textSecondary)
                    } else {
                        Text("--")
                            .font(.captionBold)
                            .foregroundStyle(Color.textSecondary)
                        Text("BPM")
                            .font(.labelText)
                            .foregroundStyle(Color.textSecondary)
                    }
                }
                .frame(width: 52, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: Radius.sm)
                        .fill(Color.surfaceElevated)
                )

                // Track info
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(track.name)
                        .font(.bodyBold)
                        .lineLimit(1)

                    Text(track.artistName)
                        .font(.captionText)
                        .foregroundStyle(Color.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                // Controls
                HStack(spacing: Spacing.lg) {
                    Button {
                        SpotifyPlayerService.shared.togglePlayPause()
                    } label: {
                        Image(systemName: playerService.isPaused ? "play.fill" : "pause.fill")
                            .font(.title3)
                    }

                    Button {
                        if RunEngineService.shared.isRunActive {
                            Task { await RunEngineService.shared.skipToNextMatch() }
                        } else {
                            SpotifyPlayerService.shared.skipNext()
                        }
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.title3)
                    }
                }
                .foregroundStyle(Color.textPrimary)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 4, y: -2)
            )
            .onChange(of: track.id) { _, newID in
                currentBPM = BPMCacheService.shared.getBPM(forTrackID: newID)
            }
            .onAppear {
                currentBPM = BPMCacheService.shared.getBPM(forTrackID: track.id)
            }
        }
    }
}
