import SwiftUI

enum BPMConfidence: String, CaseIterable {
    case verified = "verified"
    case approximate = "approximate"
    case manual = "manual"
}

// MARK: - Display Properties

extension BPMConfidence {

    var iconName: String {
        switch self {
        case .verified: return "checkmark.seal.fill"
        case .approximate: return "tilde"
        case .manual: return "hand.raised.fill"
        }
    }

    var color: Color {
        switch self {
        case .verified: return .stateSuccess
        case .approximate: return .stateApproximate
        case .manual: return .stateWarning
        }
    }
}
