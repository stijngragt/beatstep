import SwiftUI

struct MiniPlayerView: View {
    private var playerService: SpotifyPlayerService { .shared }
    @State private var currentBPM: Int?

    var body: some View {
        if let track = playerService.currentTrack {
            HStack(spacing: 12) {
                // BPM display
                VStack(spacing: 0) {
                    if let bpm = currentBPM {
                        Text("\(bpm)")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundStyle(.orange)
                        Text("BPM")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundStyle(.secondary)
                    } else {
                        Text("--")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundStyle(.secondary)
                        Text("BPM")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 52, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.15))
                )

                // Track info
                VStack(alignment: .leading, spacing: 2) {
                    Text(track.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)

                    Text(track.artistName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                // Controls
                HStack(spacing: 20) {
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
                .foregroundStyle(.primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
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
