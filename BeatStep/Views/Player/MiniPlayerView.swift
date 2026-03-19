import SwiftUI

struct MiniPlayerView: View {
    private var playerService: SpotifyPlayerService { .shared }

    var body: some View {
        if let track = playerService.currentTrack {
            HStack(spacing: 12) {
                // BPM placeholder (per CONTEXT.md: "Mini-player shows BPM instead of album art")
                Text("-- BPM")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(.secondary)
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
                        SpotifyPlayerService.shared.skipNext()
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
        }
    }
}
