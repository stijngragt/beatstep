import SwiftUI

struct RunStatusBar: View {
    let zoneName: String?
    let syncQuality: SyncQuality
    let isTrackPlaying: Bool

    var body: some View {
        HStack {
            if let zoneName {
                Text(zoneName)
                    .font(.captionBold)
                    .foregroundStyle(Color.textPrimary)
                    .transition(.opacity)
            }
            Spacer()
            if isTrackPlaying {
                SyncBadge(quality: syncQuality)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .animation(BSAnimation.smooth, value: zoneName)
    }
}

// MARK: - SyncBadge

private struct SyncBadge: View {
    let quality: SyncQuality

    var body: some View {
        HStack(spacing: Spacing.xxs) {
            Image(systemName: quality.iconName)
            Text(quality.displayLabel)
        }
        .font(.labelText)
        .foregroundStyle(quality.color)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xxs)
        .background(
            Capsule()
                .fill(quality.color.opacity(0.15))
        )
        .animation(BSAnimation.gentle, value: quality)
    }
}

// MARK: - Previews

#Preview("In Sync") {
    RunStatusBar(zoneName: "Z3 Tempo", syncQuality: .inSync, isTrackPlaying: true)
        .background(Color.surfaceBase)
}

#Preview("Free Mode") {
    RunStatusBar(zoneName: nil, syncQuality: .drifting, isTrackPlaying: true)
        .background(Color.surfaceBase)
}

#Preview("Mismatched") {
    RunStatusBar(zoneName: "Z1 Recovery", syncQuality: .mismatched, isTrackPlaying: true)
        .background(Color.surfaceBase)
}

#Preview("No Track") {
    RunStatusBar(zoneName: "Z2 Easy", syncQuality: .mismatched, isTrackPlaying: false)
        .background(Color.surfaceBase)
}
