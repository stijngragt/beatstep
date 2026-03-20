import SwiftUI

struct CadenceDisplayView: View {
    let spm: Int
    let trend: CadenceTrend

    var body: some View {
        VStack(spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text("\(spm)")
                    .font(.system(size: 76, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)

                trendArrow
            }

            Text("SPM")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
        }
    }

    private var trendArrow: some View {
        Group {
            switch trend {
            case .speedingUp:
                Image(systemName: "arrow.up")
                    .foregroundStyle(.green)
            case .steady:
                Image(systemName: "arrow.right")
                    .foregroundStyle(.white.opacity(0.5))
            case .slowingDown:
                Image(systemName: "arrow.down")
                    .foregroundStyle(.orange)
            }
        }
        .font(.system(size: 24, weight: .semibold))
    }
}
