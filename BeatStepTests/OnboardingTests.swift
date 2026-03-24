import UIKit
import XCTest
@testable import BeatStep

final class OnboardingTests: XCTestCase {

    // MARK: - AppState Resolution

    func testOnboardingNotComplete_returnsOnboarding() {
        let state = AppState.resolve(hasCompletedOnboarding: false, isAuthenticated: false)
        XCTAssertEqual(state, .onboarding)
    }

    func testOnboardingNotComplete_ignoresAuthentication() {
        let state = AppState.resolve(hasCompletedOnboarding: false, isAuthenticated: true)
        XCTAssertEqual(state, .onboarding, "Onboarding state should take precedence over authentication")
    }

    func testOnboardingComplete_notAuthenticated_returnsLogin() {
        let state = AppState.resolve(hasCompletedOnboarding: true, isAuthenticated: false)
        XCTAssertEqual(state, .login)
    }

    func testOnboardingComplete_authenticated_returnsAuthenticated() {
        let state = AppState.resolve(hasCompletedOnboarding: true, isAuthenticated: true)
        XCTAssertEqual(state, .authenticated)
    }

    func testOnboardingPrecedence_overAuth() {
        // Onboarding check must happen BEFORE auth check
        let withOnboarding = AppState.resolve(hasCompletedOnboarding: false, isAuthenticated: true)
        let withoutOnboarding = AppState.resolve(hasCompletedOnboarding: true, isAuthenticated: true)
        XCTAssertEqual(withOnboarding, .onboarding)
        XCTAssertEqual(withoutOnboarding, .authenticated)
    }

    // MARK: - Settings Permissions

    func testOpenSettingsURLString_isNonEmpty() {
        let urlString = UIApplication.openSettingsURLString
        XCTAssertFalse(urlString.isEmpty, "openSettingsURLString should be a non-empty string")
    }

    func testAppStorageFlags_defaultToFalse() {
        // Verify UserDefaults keys default to false when not set
        let defaults = UserDefaults.standard
        let testKey = "testOnboarding_hasRequestedHealth_\(UUID().uuidString)"
        XCTAssertFalse(defaults.bool(forKey: testKey), "Unset AppStorage bool should default to false")
    }
}
