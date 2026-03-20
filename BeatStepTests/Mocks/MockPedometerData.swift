import Foundation
@testable import BeatStep

/// Helper utilities for testing CadenceService.
/// Since CMPedometerData cannot be directly instantiated in tests,
/// CadenceService exposes `processCadenceSample(_:at:)` with internal access
/// so tests can feed raw cadence values directly.
enum MockPedometerData {

    /// Creates a sequence of timestamped cadence samples spaced evenly.
    /// - Parameters:
    ///   - spmValues: Array of SPM values to generate.
    ///   - interval: Time interval between samples (default 1 second).
    ///   - startDate: The starting date for the first sample.
    /// - Returns: Array of (spm, date) tuples.
    static func samples(
        spmValues: [Double],
        interval: TimeInterval = 1.0,
        startDate: Date = Date()
    ) -> [(spm: Double, date: Date)] {
        spmValues.enumerated().map { index, spm in
            (spm: spm, date: startDate.addingTimeInterval(Double(index) * interval))
        }
    }
}
