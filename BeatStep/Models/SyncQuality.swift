import Foundation

enum SyncQuality: String, CaseIterable {
    case inSync
    case drifting
    case mismatched

    /// Compute sync quality from absolute delta and tolerance.
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
