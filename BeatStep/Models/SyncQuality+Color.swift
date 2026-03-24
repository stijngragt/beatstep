import SwiftUI

extension SyncQuality {
    var color: Color {
        switch self {
        case .inSync: return .syncInSync
        case .drifting: return .syncDrifting
        case .mismatched: return .syncMismatched
        }
    }
}
