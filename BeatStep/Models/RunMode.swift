import Foundation

enum RunMode: String, CaseIterable {
    case free = "free"
    case guided = "guided"

    var displayName: String {
        switch self {
        case .free: return "Free"
        case .guided: return "Guided"
        }
    }

    // MARK: - UserDefaults Persistence

    private static let key = "selectedRunMode"

    static var saved: RunMode {
        guard let raw = UserDefaults.standard.string(forKey: key),
              let value = RunMode(rawValue: raw) else {
            return .free
        }
        return value
    }

    func save() {
        UserDefaults.standard.set(rawValue, forKey: RunMode.key)
    }

    // MARK: - Target BPM Persistence

    private static let targetBPMKey = "selectedTargetBPM"

    static var savedTargetBPM: Int {
        get {
            let value = UserDefaults.standard.integer(forKey: targetBPMKey)
            return value > 0 ? value : 160
        }
        set {
            UserDefaults.standard.set(newValue, forKey: targetBPMKey)
        }
    }
}
