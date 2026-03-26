import SwiftUI

struct PlaylistListSkeleton: View {
    private let rowCount = 7  // Per D-04: fill visible area (~6-8 rows)

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<rowCount, id: \.self) { _ in
                PlaylistRowSkeleton()
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
            }
            Spacer()
        }
        .shimmer()
    }
}

private struct PlaylistRowSkeleton: View {
    var body: some View {
        HStack(spacing: Spacing.md) {
            // Cover art placeholder (matches 56x56 from PlaylistRow)
            RoundedRectangle(cornerRadius: Radius.sm)
                .fill(Color(white: 0.165))
                .frame(width: ComponentSize.coverArtMedium,
                       height: ComponentSize.coverArtMedium)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                // Title line placeholder
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(white: 0.165))
                    .frame(width: 140, height: 14)

                // Subtitle line placeholder
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(white: 0.165))
                    .frame(width: 80, height: 11)

                // Coverage bar placeholder
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(white: 0.165))
                    .frame(height: 4)
            }
        }
        .frame(height: 70)  // Match PlaylistRow height exactly
    }
}
