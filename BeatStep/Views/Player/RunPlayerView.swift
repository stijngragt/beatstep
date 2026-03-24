import SwiftUI

struct RunPlayerView: View {
    let track: SpotifyTrack
    let isPaused: Bool
    let trackBPM: Int?
    let onPlayPause: () -> Void
    let onSkip: () -> Void

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Album art
            AsyncImage(url: Self.selectAlbumArtURL(from: track.album.images)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                default:
                    RoundedRectangle(cornerRadius: Radius.sm)
                        .fill(Color.surfaceOverlay)
                        .overlay(
                            Image(systemName: "music.note")
                                .foregroundStyle(Color.textTertiary)
                        )
                }
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: Radius.sm))

            // Track info
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(track.name)
                    .font(.bodyBold)
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)

                Text(track.artistName)
                    .font(.captionText)
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(1)

                if let bpm = trackBPM {
                    Text("\(bpm) BPM")
                        .font(.captionBold)
                        .foregroundStyle(Color.stateWarning)
                }
            }

            Spacer()

            // Playback controls
            HStack(spacing: Spacing.lg) {
                Button(action: onPlayPause) {
                    Image(systemName: isPaused ? "play.fill" : "pause.fill")
                        .font(.system(size: 28))
                        .frame(width: 56, height: 56)
                        .background(Circle().fill(Color.surfaceOverlay))
                }

                Button(action: onSkip) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 28))
                        .frame(width: 56, height: 56)
                        .background(Circle().fill(Color.surfaceOverlay))
                }
            }
            .foregroundStyle(Color.textPrimary)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Radius.md)
                .fill(Color.surfaceElevated)
        )
    }

    // MARK: - Album Art URL Selection

    static func selectAlbumArtURL(from images: [SpotifyImage]?) -> URL? {
        guard let images, !images.isEmpty else { return nil }

        // Prefer mid-size image (200-400px) for 80pt @3x display
        if let midSize = images.first(where: { ($0.width ?? 0) >= 200 && ($0.width ?? 0) <= 400 }) {
            return URL(string: midSize.url)
        }

        // Fall back to first available image
        return URL(string: images[0].url)
    }
}

// MARK: - Previews

#Preview("Playing Track") {
    let track = SpotifyTrack(
        id: "1",
        name: "Blinding Lights",
        uri: "spotify:track:1",
        durationMs: 200_000,
        artists: [Artist(name: "The Weeknd")],
        album: Album(
            name: "After Hours",
            images: [
                SpotifyImage(url: "https://i.scdn.co/image/ab67616d0000b273ef017e899c0547766997f41a", width: 640, height: 640),
                SpotifyImage(url: "https://i.scdn.co/image/ab67616d00001e02ef017e899c0547766997f41a", width: 300, height: 300),
                SpotifyImage(url: "https://i.scdn.co/image/ab67616d00004851ef017e899c0547766997f41a", width: 64, height: 64),
            ]
        )
    )
    RunPlayerView(
        track: track,
        isPaused: false,
        trackBPM: 128,
        onPlayPause: {},
        onSkip: {}
    )
    .background(Color.surfaceBase)
}

#Preview("Paused No BPM") {
    let track = SpotifyTrack(
        id: "2",
        name: "Levitating",
        uri: "spotify:track:2",
        durationMs: 203_000,
        artists: [Artist(name: "Dua Lipa")],
        album: Album(
            name: "Future Nostalgia",
            images: [
                SpotifyImage(url: "https://i.scdn.co/image/ab67616d0000b273d4daf28d55fe4197ede848be", width: 640, height: 640),
            ]
        )
    )
    RunPlayerView(
        track: track,
        isPaused: true,
        trackBPM: nil,
        onPlayPause: {},
        onSkip: {}
    )
    .background(Color.surfaceBase)
}
