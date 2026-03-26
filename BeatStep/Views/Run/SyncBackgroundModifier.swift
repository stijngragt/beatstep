import SwiftUI

struct SyncBackgroundModifier: ViewModifier {
    let syncQuality: SyncQuality

    private var backgroundColor: Color {
        syncQuality.color
    }

    func body(content: Content) -> some View {
        content
            .background(
                backgroundColor.opacity(0.08)
                    .ignoresSafeArea()
                    .animation(BSAnimation.gentle, value: syncQuality)
            )
    }
}

extension View {
    func syncBackground(_ quality: SyncQuality) -> some View {
        modifier(SyncBackgroundModifier(syncQuality: quality))
    }
}

// MARK: - Previews

#Preview("In Sync Background") {
    VStack(spacing: Spacing.lg) {
        Text("Content with sync background")
            .font(.bodyText)
            .foregroundStyle(Color.textPrimary)
        Text("170 SPM")
            .font(.displaySPM)
            .foregroundStyle(Color.textPrimary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .syncBackground(.inSync)
    .background(Color.surfaceBase)
}

#Preview("Drifting Background") {
    VStack(spacing: Spacing.lg) {
        Text("Content with sync background")
            .font(.bodyText)
            .foregroundStyle(Color.textPrimary)
        Text("165 SPM")
            .font(.displaySPM)
            .foregroundStyle(Color.textPrimary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .syncBackground(.drifting)
    .background(Color.surfaceBase)
}
