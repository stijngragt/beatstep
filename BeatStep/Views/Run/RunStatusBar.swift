import SwiftUI

struct RunStatusBar: View {
    let zoneName: String?
    let syncQuality: SyncQuality

    var body: some View {
        HStack {
            if let zoneName {
                Text(zoneName)
                    .font(.captionBold)
                    .foregroundStyle(Color.textPrimary)
            }
            Spacer()
            SyncBadge(quality: syncQuality)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
    }
}

// MARK: - SyncBadge

private struct SyncBadge: View {
    let quality: SyncQuality

    var body: some View {
        Text(quality.displayLabel)
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
    RunStatusBar(zoneName: "Z3 Tempo", syncQuality: .inSync)
        .background(Color.surfaceBase)
}

#Preview("Free Mode") {
    RunStatusBar(zoneName: nil, syncQuality: .drifting)
        .background(Color.surfaceBase)
}

#Preview("Mismatched") {
    RunStatusBar(zoneName: "Z1 Recovery", syncQuality: .mismatched)
        .background(Color.surfaceBase)
}
