import SwiftUI

struct RampPhaseIndicator: View {
    let rampPhase: RampPhase
    let effectiveBPM: Int
    let targetBPM: Int

    /// Compute ramp progress (0.0-1.0) based on phase and current effective BPM.
    static func progress(phase: RampPhase, effectiveBPM: Int, targetBPM: Int) -> Double {
        // Stub: return -1 to fail tests
        return -1.0
    }

    var body: some View {
        Text("TODO")
    }
}
