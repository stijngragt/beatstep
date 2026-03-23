import Foundation

enum PacePreset: String, CaseIterable, Identifiable {
    case easyJog
    case steady
    case tempo
    case fast
    case sprint
    case custom

    var id: String { rawValue }

    var bpm: Int? {
        switch self {
        case .easyJog: return 150
        case .steady: return 160
        case .tempo: return 170
        case .fast: return 180
        case .sprint: return 190
        case .custom: return nil
        }
    }

    var displayName: String {
        switch self {
        case .easyJog: return "Easy Jog"
        case .steady: return "Steady"
        case .tempo: return "Tempo"
        case .fast: return "Fast"
        case .sprint: return "Sprint"
        case .custom: return "Custom"
        }
    }
}
