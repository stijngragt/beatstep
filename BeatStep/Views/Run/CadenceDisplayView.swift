import SwiftUI

struct CadenceDisplayView: View {
    let spm: Int
    let trend: CadenceTrend
    let syncQuality: SyncQuality
    let cadenceDelta: Int
    let isGuidedMode: Bool

    var body: some View {
        VStack(spacing: Spacing.xs) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.md) {
                Text("\(spm)")
                    .font(.displaySPM)
                    .foregroundStyle(syncQuality.color)

                trendArrow
            }

            // Delta or sync label between SPM number and "SPM" label
            Group {
                if isGuidedMode {
                    deltaLabel
                        .transition(.opacity)
                } else {
                    Text(syncQuality.displayLabel)
                        .font(.captionBold)
                        .foregroundStyle(syncQuality.color)
                        .transition(.opacity)
                }
            }
            .animation(BSAnimation.smooth, value: isGuidedMode)

            Text("SPM")
                .font(.displaySecondary)
                .foregroundStyle(Color.textSecondary)
        }
    }

    private var deltaLabel: some View {
        Text(cadenceDelta >= 0 ? "+\(cadenceDelta)" : "\(cadenceDelta)")
            .font(.captionBold)
            .foregroundStyle(syncQuality.color)
    }

    private var trendArrow: some View {
        Group {
            switch trend {
            case .speedingUp:
                Image(systemName: "arrow.up")
                    .foregroundStyle(Color.stateSuccess)
            case .steady:
                Image(systemName: "arrow.right")
                    .foregroundStyle(Color.textSecondary)
            case .slowingDown:
                Image(systemName: "arrow.down")
                    .foregroundStyle(Color.stateWarning)
            }
        }
        .font(.system(size: 24, weight: .semibold))
        .animation(BSAnimation.quick, value: trend)
    }
}

// MARK: - Previews

#Preview("Guided - In Sync +2") {
    CadenceDisplayView(
        spm: 174,
        trend: .steady,
        syncQuality: .inSync,
        cadenceDelta: 2,
        isGuidedMode: true
    )
    .background(Color.surfaceBase)
}

#Preview("Guided - Drifting -8") {
    CadenceDisplayView(
        spm: 166,
        trend: .slowingDown,
        syncQuality: .drifting,
        cadenceDelta: -8,
        isGuidedMode: true
    )
    .background(Color.surfaceBase)
}

#Preview("Free - Mismatched") {
    CadenceDisplayView(
        spm: 152,
        trend: .slowingDown,
        syncQuality: .mismatched,
        cadenceDelta: 0,
        isGuidedMode: false
    )
    .background(Color.surfaceBase)
}

#Preview("Free - In Sync") {
    CadenceDisplayView(
        spm: 174,
        trend: .steady,
        syncQuality: .inSync,
        cadenceDelta: 0,
        isGuidedMode: false
    )
    .background(Color.surfaceBase)
}
