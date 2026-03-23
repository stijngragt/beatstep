import SwiftUI

struct CadenceDisplayView: View {
    let spm: Int
    let trend: CadenceTrend

    var body: some View {
        VStack(spacing: Spacing.xs) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.md) {
                Text("\(spm)")
                    .font(.displaySPM)
                    .foregroundStyle(Color.textPrimary)

                trendArrow
            }

            Text("SPM")
                .font(.displaySecondary)
                .foregroundStyle(Color.textSecondary)
        }
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
    }
}
