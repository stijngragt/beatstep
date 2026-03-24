import SwiftUI

struct RampPhaseIndicator: View {
    let rampPhase: RampPhase
    let effectiveBPM: Int
    let targetBPM: Int

    /// Compute ramp progress (0.0-1.0) based on phase and current effective BPM.
    /// Warm-up starts at 140 BPM (consistent with engine).
    static func progress(phase: RampPhase, effectiveBPM: Int, targetBPM: Int) -> Double {
        switch phase {
        case .warmUp:
            let start = 140
            let range = Double(targetBPM - start)
            guard range > 0 else { return 1.0 }
            return min(max(Double(effectiveBPM - start) / range, 0.0), 1.0)
        case .atPace:
            return 1.0
        case .coolDown:
            let start = 140
            let range = Double(targetBPM - start)
            guard range > 0 else { return 0.0 }
            return min(max(Double(effectiveBPM - start) / range, 0.0), 1.0)
        }
    }

    private var currentProgress: Double {
        Self.progress(phase: rampPhase, effectiveBPM: effectiveBPM, targetBPM: targetBPM)
    }

    var body: some View {
        VStack(spacing: Spacing.xs) {
            Text(rampPhase.displayLabel)
                .font(.captionBold)
                .foregroundStyle(Color.textSecondary)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.surfaceOverlay)
                    Capsule()
                        .fill(Color.accent)
                        .frame(width: geo.size.width * currentProgress)
                        .animation(.easeInOut(duration: 0.5), value: effectiveBPM)
                }
            }
            .frame(height: 4)
        }
    }
}

// MARK: - Previews

#Preview("Warming Up - Early") {
    RampPhaseIndicator(
        rampPhase: .warmUp,
        effectiveBPM: 148,
        targetBPM: 174
    )
    .padding(.horizontal, Spacing.xl)
    .background(Color.surfaceBase)
}

#Preview("Warming Up - Almost Done") {
    RampPhaseIndicator(
        rampPhase: .warmUp,
        effectiveBPM: 170,
        targetBPM: 174
    )
    .padding(.horizontal, Spacing.xl)
    .background(Color.surfaceBase)
}

#Preview("At Pace") {
    RampPhaseIndicator(
        rampPhase: .atPace,
        effectiveBPM: 174,
        targetBPM: 174
    )
    .padding(.horizontal, Spacing.xl)
    .background(Color.surfaceBase)
}

#Preview("Cooling Down") {
    RampPhaseIndicator(
        rampPhase: .coolDown,
        effectiveBPM: 156,
        targetBPM: 174
    )
    .padding(.horizontal, Spacing.xl)
    .background(Color.surfaceBase)
}
