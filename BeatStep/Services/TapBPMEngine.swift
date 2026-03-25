import Foundation

@Observable
final class TapBPMEngine {

    // MARK: - Published State

    private(set) var currentBPM: Int?
    private(set) var tapCount: Int = 0
    private(set) var isStable: Bool = false
    private(set) var lastTapWasOutlier: Bool = false

    var canSave: Bool {
        intervals.count >= 3
    }

    // MARK: - Internal State

    private var tapTimestamps: [Date] = []
    private var intervals: [TimeInterval] = []
    private var inactivityTimer: Timer?

    private let maxIntervals = 8
    private let inactivityTimeout: TimeInterval = 3.0
    private let outlierThreshold: Double = 0.40

    // MARK: - Public API

    func tap() {
        tap(at: Date())
    }

    func tap(at date: Date) {
        resetInactivityTimer()

        guard let lastTap = tapTimestamps.last else {
            // First tap -- no interval yet
            tapTimestamps.append(date)
            tapCount = 1
            lastTapWasOutlier = false
            return
        }

        let interval = date.timeIntervalSince(lastTap)

        // Reject unreasonable intervals (< 0.2s = 300 BPM, > 2.0s = 30 BPM)
        guard interval >= 0.2 && interval <= 2.0 else {
            lastTapWasOutlier = true
            return
        }

        // Outlier check against existing intervals (median deviation > 40%)
        if !intervals.isEmpty && isOutlier(interval) {
            lastTapWasOutlier = true
            return
        }

        // Valid tap
        tapTimestamps.append(date)
        intervals.append(interval)

        // Keep rolling window of last 8 intervals
        if intervals.count > maxIntervals {
            intervals.removeFirst()
        }

        tapCount = min(intervals.count + 1, maxIntervals + 1)
        lastTapWasOutlier = false
        isStable = intervals.count >= maxIntervals

        // Calculate BPM from average interval
        let avgInterval = intervals.reduce(0, +) / Double(intervals.count)
        currentBPM = Int(round(60.0 / avgInterval))
    }

    func reset() {
        tapTimestamps.removeAll()
        intervals.removeAll()
        currentBPM = nil
        tapCount = 0
        isStable = false
        lastTapWasOutlier = false
        inactivityTimer?.invalidate()
        inactivityTimer = nil
    }

    // MARK: - Private

    private func isOutlier(_ interval: TimeInterval) -> Bool {
        let sorted = intervals.sorted()
        let median = sorted[sorted.count / 2]
        let deviation = abs(interval - median) / median
        return deviation > outlierThreshold
    }

    private func resetInactivityTimer() {
        inactivityTimer?.invalidate()
        inactivityTimer = Timer.scheduledTimer(
            withTimeInterval: inactivityTimeout,
            repeats: false
        ) { [weak self] _ in
            Task { @MainActor in
                self?.reset()
            }
        }
    }
}
