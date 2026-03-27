import Foundation

enum SyncQuality: String, CaseIterable {
    case inSync
    case drifting
    case mismatched

    var iconName: String {
        switch self {
        case .inSync: return "waveform.path.ecg"
        case .drifting: return "waveform.badge.minus"
        case .mismatched: return "waveform.slash"
        }
    }

    /// Compute sync quality with half/double-tempo normalization.
    /// Compares SPM against trackBPM, trackBPM*2, and trackBPM/2,
    /// using the smallest absolute delta for quality classification.
    static func from(spm: Int, trackBPM: Int, tolerance: BPMTolerance) -> SyncQuality {
        guard trackBPM > 0 else { return .mismatched }
        let candidates = [trackBPM, trackBPM * 2, trackBPM / 2].filter { $0 > 0 }
        let bestDelta = candidates.map { abs(spm - $0) }.min() ?? abs(spm - trackBPM)
        let range = tolerance.range
        if bestDelta <= range {
            return .inSync
        } else if bestDelta <= range * 2 {
            return .drifting
        } else {
            return .mismatched
        }
    }

    /// Compute sync quality from absolute delta and tolerance (legacy, prefer from(spm:trackBPM:tolerance:) for sync badge display).
    /// - inSync: abs(delta) <= tolerance range
    /// - drifting: abs(delta) <= 2x tolerance range
    /// - mismatched: abs(delta) > 2x tolerance range
    static func from(delta: Int, tolerance: BPMTolerance) -> SyncQuality {
        let absDelta = abs(delta)
        let range = tolerance.range
        if absDelta <= range {
            return .inSync
        } else if absDelta <= range * 2 {
            return .drifting
        } else {
            return .mismatched
        }
    }

    var displayLabel: String {
        switch self {
        case .inSync: return "In Sync"
        case .drifting: return "Drifting"
        case .mismatched: return "Mismatched"
        }
    }
}
