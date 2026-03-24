import Foundation

enum BPMTolerance: String, CaseIterable {
    case tight = "tight"
    case normal = "normal"
    case loose = "loose"

    var range: Int {
        switch self {
        case .tight: return 3
        case .normal: return 7
        case .loose: return 12
        }
    }

    var displayName: String {
        "\u{00B1}\(range) BPM"
    }

    var description: String {
        "\u{00B1}\(range) BPM"
    }

    static var defaultTolerance: BPMTolerance { .normal }

    // MARK: - UserDefaults Persistence

    private static let key = "selectedBPMTolerance"

    static var saved: BPMTolerance {
        guard let raw = UserDefaults.standard.string(forKey: key),
              let value = BPMTolerance(rawValue: raw) else {
            return .defaultTolerance
        }
        return value
    }

    func save() {
        UserDefaults.standard.set(rawValue, forKey: BPMTolerance.key)
    }
}
