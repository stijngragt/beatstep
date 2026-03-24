import Foundation

enum AppState {
    case onboarding
    case login
    case authenticated

    static func resolve(hasCompletedOnboarding: Bool, isAuthenticated: Bool) -> AppState {
        guard hasCompletedOnboarding else { return .onboarding }
        return isAuthenticated ? .authenticated : .login
    }
}
