import SwiftUI

struct ZoneBandView: View {
    let targetBPM: Int
    let toleranceRange: Int
    let currentCadence: Int
    let syncQuality: SyncQuality

    /// Compute normalized position (0.0-1.0) within the zone band.
    /// Band spans 2x tolerance range on each side of targetBPM (full drifting zone).
    static func position(cadence: Int, targetBPM: Int, toleranceRange: Int) -> Double {
        let bandMin = targetBPM - 2 * toleranceRange
        let bandMax = targetBPM + 2 * toleranceRange
        let range = Double(bandMax - bandMin)
        guard range > 0 else { return 0.5 }
        let raw = Double(cadence - bandMin) / range
        return min(max(raw, 0.0), 1.0)
    }

    private var normalizedPosition: Double {
        Self.position(cadence: currentCadence, targetBPM: targetBPM, toleranceRange: toleranceRange)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Full band background
                Capsule()
                    .fill(Color.surfaceOverlay)

                // Center zone (inSync zone = 1x tolerance on each side)
                // Positioned at 25%-75% of the band (since band is 2x tolerance each side)
                Capsule()
                    .fill(syncQuality.color.opacity(0.3))
                    .frame(width: geo.size.width * 0.5)
                    .offset(x: geo.size.width * 0.25)

                // Cadence position indicator
                Circle()
                    .fill(syncQuality.color)
                    .frame(width: 12, height: 12)
                    .offset(x: normalizedPosition * (geo.size.width - 12))
                    .animation(BSAnimation.smooth, value: currentCadence)
            }
        }
        .frame(height: 12)
    }
}

// MARK: - Previews

#Preview("Centered - In Sync") {
    ZoneBandView(
        targetBPM: 174,
        toleranceRange: 7,
        currentCadence: 174,
        syncQuality: .inSync
    )
    .padding(.horizontal, Spacing.xl)
    .background(Color.surfaceBase)
}

#Preview("Edge - Drifting") {
    ZoneBandView(
        targetBPM: 174,
        toleranceRange: 7,
        currentCadence: 182,
        syncQuality: .drifting
    )
    .padding(.horizontal, Spacing.xl)
    .background(Color.surfaceBase)
}

#Preview("Far Out - Mismatched") {
    ZoneBandView(
        targetBPM: 174,
        toleranceRange: 7,
        currentCadence: 190,
        syncQuality: .mismatched
    )
    .padding(.horizontal, Spacing.xl)
    .background(Color.surfaceBase)
}
