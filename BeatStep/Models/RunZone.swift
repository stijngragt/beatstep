import Foundation

struct RunZone: Identifiable, Equatable {
    let id: Int
    let name: String
    var bpm: Int

    var displayLabel: String {
        "Z\(id) \(name)"
    }

    // MARK: - Defaults

    static let defaults: [RunZone] = [
        RunZone(id: 1, name: "Recovery", bpm: 155),
        RunZone(id: 2, name: "Endurance", bpm: 165),
        RunZone(id: 3, name: "Tempo", bpm: 174),
        RunZone(id: 4, name: "Threshold", bpm: 178),
        RunZone(id: 5, name: "Max", bpm: 185),
    ]

    // MARK: - UserDefaults Persistence

    private static let key = "runZoneBPMs"

    static var saved: [RunZone] {
        guard let dict = UserDefaults.standard.dictionary(forKey: key) as? [String: Int] else {
            return defaults
        }
        return defaults.map { zone in
            var z = zone
            if let persisted = dict["\(zone.id)"] {
                z.bpm = persisted
            }
            return z
        }
    }

    static func saveAll(_ zones: [RunZone]) {
        let dict = Dictionary(uniqueKeysWithValues: zones.map { ("\($0.id)", $0.bpm) })
        UserDefaults.standard.set(dict, forKey: key)
    }

    static func resetToDefaults() {
        UserDefaults.standard.removeObject(forKey: key)
    }

    // MARK: - Selected Zone Persistence

    private static let selectedKey = "selectedRunZoneId"

    static var selectedZoneId: Int? {
        get {
            let value = UserDefaults.standard.integer(forKey: selectedKey)
            return value == 0 ? nil : value
        }
        set {
            UserDefaults.standard.set(newValue ?? 0, forKey: selectedKey)
        }
    }
}
