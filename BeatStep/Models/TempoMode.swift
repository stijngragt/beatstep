import Foundation

enum TempoMode: String, CaseIterable {
    case oneToOne = "oneToOne"
    case half = "half"

    var displayName: String {
        switch self {
        case .oneToOne: return "1:1"
        case .half: return "1/2"
        }
    }

    // MARK: - UserDefaults Persistence

    private static let key = "selectedTempoMode"

    static var saved: TempoMode {
        guard let raw = UserDefaults.standard.string(forKey: key),
              let value = TempoMode(rawValue: raw) else {
            return .oneToOne
        }
        return value
    }

    func save() {
        UserDefaults.standard.set(rawValue, forKey: TempoMode.key)
    }
}
