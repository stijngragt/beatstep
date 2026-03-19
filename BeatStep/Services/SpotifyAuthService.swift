import Foundation
import SwiftUI

@Observable
class SpotifyAuthService {
    static let shared = SpotifyAuthService()

    var isAuthenticated = false
    var isCheckingAuth = false
    var isPremium = false
    var currentUser: SpotifyUser?
    var authError: String?

    private init() {}

    func initiateAuth() {
        // Will be implemented in Task 2
    }

    func handleCallback(url: URL) {
        // Will be implemented in Task 2
    }

    func checkPremiumStatus() async {
        // Will be implemented in Task 2
    }

    func disconnect() {
        // Will be implemented in Task 2
    }

    func checkExistingAuth() {
        // Will be implemented in Task 2
    }
}
