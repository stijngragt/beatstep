import SwiftUI

struct LongPressStopButton: View {
    var onStop: () -> Void

    @State private var pressTimer: Timer?
    @State private var pressStart: Date?
    @State private var currentProgress: CGFloat = 0

    private let duration: TimeInterval = 2.0

    /// Compute normalized progress (0.0-1.0) for elapsed time within duration.
    /// Clamped to [0, 1] to prevent overshoot or negative values.
    static func progress(elapsed: TimeInterval, duration: TimeInterval) -> CGFloat {
        guard duration > 0 else { return 0 }
        return min(max(CGFloat(elapsed / duration), 0.0), 1.0)
    }

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.surfaceOverlay, lineWidth: 4)

            // Progress ring
            Circle()
                .trim(from: 0, to: currentProgress)
                .stroke(Color.stateError, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))

            // Stop icon
            Image(systemName: "stop.fill")
                .font(.system(size: 20))
                .foregroundStyle(pressStart != nil ? Color.stateError : Color.textSecondary)
        }
        .frame(width: 56, height: 56)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard pressTimer == nil else { return }
                    startPress()
                }
                .onEnded { _ in
                    cancelPress()
                }
        )
    }

    // MARK: - Timer Logic

    private func startPress() {
        pressStart = Date()
        pressTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { _ in
            guard let start = pressStart else { return }
            let elapsed = Date().timeIntervalSince(start)
            currentProgress = Self.progress(elapsed: elapsed, duration: duration)
            if currentProgress >= 1.0 {
                pressTimer?.invalidate()
                pressTimer = nil
                pressStart = nil
                onStop()
            }
        }
    }

    private func cancelPress() {
        pressTimer?.invalidate()
        pressTimer = nil
        pressStart = nil
        withAnimation(.easeOut(duration: 0.2)) {
            currentProgress = 0
        }
    }
}

// MARK: - Previews

#Preview("Default") {
    LongPressStopButton(onStop: {})
        .background(Color.surfaceBase)
}

#Preview("On Dark Background") {
    ZStack {
        Color.surfaceBase.ignoresSafeArea()
        LongPressStopButton(onStop: {})
    }
}
