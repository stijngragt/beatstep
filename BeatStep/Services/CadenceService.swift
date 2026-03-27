import Foundation
import CoreMotion

@Observable
final class CadenceService {
    static let shared = CadenceService()

    // MARK: - Observable State

    var currentSPM: Int = 0
    var stepCount: Int = 0
    var trend: CadenceTrend = .steady
    var state: CadenceState = .idle
    var permissionDenied: Bool = false

    // MARK: - Private

    @ObservationIgnored
    private var pedometer: CMPedometer?
    @ObservationIgnored
    private var cadenceWindow: [(timestamp: Date, cadence: Double)] = []
    @ObservationIgnored
    private let windowDuration: TimeInterval = 2.5
    @ObservationIgnored
    private var lastStepTime: Date?
    @ObservationIgnored
    private var trendHistory: [Double] = []
    @ObservationIgnored
    private var inactivityTimer: Timer?
    @ObservationIgnored
    private var previousStepCount: Int?
    @ObservationIgnored
    private var previousStepTime: Date?

    private init() {}

    // MARK: - Lifecycle

    func requestPermissionAndStart() {
        let status = CMPedometer.authorizationStatus()
        switch status {
        case .authorized:
            startDetecting()
        case .notDetermined:
            // Will trigger system prompt
            startDetecting()
        case .denied, .restricted:
            permissionDenied = true
        @unknown default:
            startDetecting()
        }
    }

    func startDetecting() {
        guard CMPedometer.isCadenceAvailable() else { return }
        state = .detecting

        if pedometer == nil { pedometer = CMPedometer() }
        pedometer?.startUpdates(from: Date()) { [weak self] data, error in
            guard let self, let data else { return }
            DispatchQueue.main.async {
                self.handlePedometerData(data)
            }
        }

        startInactivityMonitor()
    }

    func stopDetecting() {
        pedometer?.stopUpdates()
        inactivityTimer?.invalidate()
        inactivityTimer = nil
        cadenceWindow.removeAll()
        trendHistory.removeAll()
        lastStepTime = nil
        previousStepCount = nil
        previousStepTime = nil
        state = .idle
        currentSPM = 0
        stepCount = 0
        trend = .steady
    }

    // MARK: - Processing (internal for testing)

    func processCadenceSample(_ spm: Double, at timestamp: Date) {
        // Add to window
        cadenceWindow.append((timestamp: timestamp, cadence: spm))

        // Prune old samples outside window
        cadenceWindow.removeAll { timestamp.timeIntervalSince($0.timestamp) > windowDuration }

        // Compute rolling average
        guard !cadenceWindow.isEmpty else { return }
        let avgSPM = cadenceWindow.map(\.cadence).reduce(0, +) / Double(cadenceWindow.count)
        // Dead zone filter: only update displayed SPM when change is significant
        let rounded = Int(avgSPM.rounded())
        let deadZone = 3
        if abs(rounded - currentSPM) >= deadZone || currentSPM == 0 {
            currentSPM = rounded
        }

        // Transition from detecting to active on first sample
        if state == .detecting {
            state = .active
        }

        // Resume from paused when movement resumes
        if state == .paused {
            state = .active
        }

        // Update step time
        lastStepTime = timestamp

        // Update trend
        updateTrend(currentAvg: avgSPM)
    }

    // MARK: - Private

    private func handlePedometerData(_ data: CMPedometerData) {
        stepCount = data.numberOfSteps.intValue
        let now = Date()
        lastStepTime = now

        if let cadence = data.currentCadence?.doubleValue {
            let spm = cadence * 60.0
            processCadenceSample(spm, at: now)
        } else {
            // Fallback: compute cadence from step delta / time delta
            let currentSteps = data.numberOfSteps.intValue
            if let prevSteps = previousStepCount,
               let prevTime = previousStepTime {
                let stepDelta = currentSteps - prevSteps
                let timeDelta = now.timeIntervalSince(prevTime)
                if timeDelta > 0 && stepDelta > 0 {
                    let spm = (Double(stepDelta) / timeDelta) * 60.0
                    processCadenceSample(spm, at: now)
                }
            }
            previousStepCount = currentSteps
            previousStepTime = now
        }
    }

    private func updateTrend(currentAvg: Double) {
        trendHistory.append(currentAvg)

        // Keep last 5 samples (roughly 5 seconds at ~1 update/sec)
        let maxSamples = 5
        if trendHistory.count > maxSamples {
            trendHistory.removeFirst(trendHistory.count - maxSamples)
        }

        guard trendHistory.count >= 3 else {
            trend = .steady
            return
        }

        let first = trendHistory.first!
        let last = trendHistory.last!
        let delta = last - first
        let threshold: Double = 5.0

        if delta > threshold {
            trend = .speedingUp
        } else if delta < -threshold {
            trend = .slowingDown
        } else {
            trend = .steady
        }
    }

    private func startInactivityMonitor() {
        inactivityTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            DispatchQueue.main.async {
                if let last = self.lastStepTime,
                   Date().timeIntervalSince(last) > 5.0,
                   self.state == .active {
                    self.state = .paused
                }
            }
        }
    }
}
