import SwiftUI

struct PlaylistDetailSkeleton: View {
    private let rowCount = 8  // Per D-04: fill visible area

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<rowCount, id: \.self) { _ in
                TrackRowSkeleton()
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
            }
            Spacer()
        }
        .shimmer()
    }
}

private struct TrackRowSkeleton: View {
    var body: some View {
        HStack(spacing: Spacing.md) {
            // Track number placeholder
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(white: 0.165))
                .frame(width: 16, height: 14)
                .frame(width: 28)

            // Track info placeholder
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                // Title
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(white: 0.165))
                    .frame(width: 180, height: 14)
                // Artist
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(white: 0.165))
                    .frame(width: 100, height: 11)
            }

            Spacer()

            // BPM badge placeholder
            RoundedRectangle(cornerRadius: Radius.sm)
                .fill(Color(white: 0.165))
                .frame(width: 64, height: 24)

            // Duration placeholder
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(white: 0.165))
                .frame(width: 32, height: 11)
        }
    }
}
