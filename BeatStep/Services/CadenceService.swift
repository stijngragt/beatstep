import Foundation
import CoreMotion

@Observable
final class CadenceService {
    static let shared = CadenceService()

    // MARK: - Observable State

    var currentSPM: Int = 0
    var trend: CadenceTrend = .steady
    var state: CadenceState = .idle
    var permissionDenied: Bool = false

    // MARK: - Private

    private let pedometer = CMPedometer()
    private var cadenceWindow: [(timestamp: Date, cadence: Double)] = []
    private let windowDuration: TimeInterval = 5.0
    private var lastStepTime: Date?
    private var trendHistory: [Double] = []
    private var inactivityTimer: Timer?

    private init() {}

    // MARK: - Lifecycle

    func requestPermissionAndStart() {
        // Stub - will be implemented in GREEN phase
    }

    func startDetecting() {
        // Stub - will be implemented in GREEN phase
    }

    func stopDetecting() {
        // Stub - will be implemented in GREEN phase
    }

    // MARK: - Processing (internal for testing)

    func processCadenceSample(_ spm: Double, at timestamp: Date) {
        // Stub - will be implemented in GREEN phase
    }

    // MARK: - Trend

    private func updateTrend(currentAvg: Double) {
        // Stub - will be implemented in GREEN phase
    }
}
