import Foundation
import KeychainAccess

final class KeychainManager {
    static let shared = KeychainManager()

    private let keychain = Keychain(service: "com.beatstep.app")

    private enum Keys {
        static let accessToken = "access_token"
        static let refreshToken = "refresh_token"
        static let tokenExpiration = "token_expiration"
    }

    private init() {}

    var accessToken: String? {
        get {
            try? keychain.get(Keys.accessToken)
        }
        set {
            if let newValue {
                try? keychain.set(newValue, key: Keys.accessToken)
            } else {
                try? keychain.remove(Keys.accessToken)
            }
        }
    }

    var refreshToken: String? {
        get {
            try? keychain.get(Keys.refreshToken)
        }
        set {
            if let newValue {
                try? keychain.set(newValue, key: Keys.refreshToken)
            } else {
                try? keychain.remove(Keys.refreshToken)
            }
        }
    }

    var tokenExpirationDate: Date? {
        get {
            guard let string = try? keychain.get(Keys.tokenExpiration),
                  let interval = TimeInterval(string) else {
                return nil
            }
            return Date(timeIntervalSince1970: interval)
        }
        set {
            if let newValue {
                try? keychain.set(
                    String(newValue.timeIntervalSince1970),
                    key: Keys.tokenExpiration
                )
            } else {
                try? keychain.remove(Keys.tokenExpiration)
            }
        }
    }

    func clearAll() {
        try? keychain.removeAll()
    }
}
