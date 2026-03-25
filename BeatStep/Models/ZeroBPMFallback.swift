import Foundation

enum ZeroBPMFallback: String, CaseIterable {
    case skip = "skip"
    case playRegardless = "playRegardless"
    case prompt = "prompt"

    var displayName: String {
        switch self {
        case .skip: return "Skip"
        case .playRegardless: return "Play Anyway"
        case .prompt: return "Ask Me"
        }
    }

    // MARK: - UserDefaults Persistence

    private static let key = "zeroBPMFallback"

    static var saved: ZeroBPMFallback {
        guard let raw = UserDefaults.standard.string(forKey: key),
              let value = ZeroBPMFallback(rawValue: raw) else {
            return .skip
        }
        return value
    }

    func save() {
        UserDefaults.standard.set(rawValue, forKey: ZeroBPMFallback.key)
    }
}
