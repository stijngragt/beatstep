import Foundation

enum RampPhase: String {
    case warmUp
    case atPace
    case coolDown

    var displayLabel: String {
        switch self {
        case .warmUp: return "Warming up"
        case .atPace: return "At pace"
        case .coolDown: return "Cooling down"
        }
    }
}
