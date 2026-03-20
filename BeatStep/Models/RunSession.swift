import Foundation

/// Represents the current state of cadence detection during a run.
enum CadenceState {
    /// Not running, run screen in pre-run mode
    case idle
    /// First ~5 seconds, showing "Detecting..."
    case detecting
    /// Cadence locked, showing SPM + trend
    case active
    /// No steps detected for ~5 seconds
    case paused
}

/// Represents the direction of cadence change.
enum CadenceTrend {
    case speedingUp
    case steady
    case slowingDown
}
