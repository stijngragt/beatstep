import XCTest
import SwiftUI
@testable import BeatStep

final class DesignTokenTests: XCTestCase {

    // MARK: - Color Tokens

    func testAccentColorComponents() {
        let uiColor = UIColor(Color.accent)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)

        XCTAssertEqual(r, 1.0, accuracy: 0.01, "Accent red should be 1.0")
        XCTAssertEqual(g, 0.271, accuracy: 0.01, "Accent green should be 0.271")
        XCTAssertEqual(b, 0.271, accuracy: 0.01, "Accent blue should be 0.271")
        XCTAssertEqual(a, 1.0, accuracy: 0.01, "Accent alpha should be 1.0")
    }

    func testSpotifyBrandColorComponents() {
        let uiColor = UIColor(Color.spotifyBrand)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)

        XCTAssertEqual(r, 0.114, accuracy: 0.01)
        XCTAssertEqual(g, 0.725, accuracy: 0.01)
        XCTAssertEqual(b, 0.329, accuracy: 0.01)
    }

    func testBackgroundLevelsAreDistinct() {
        let base = UIColor(Color.surfaceBase)
        let elevated = UIColor(Color.surfaceElevated)
        let overlay = UIColor(Color.surfaceOverlay)

        var baseW: CGFloat = 0, elevW: CGFloat = 0, overlayW: CGFloat = 0
        var a: CGFloat = 0

        // Extract white component (grayscale brightness)
        base.getWhite(&baseW, alpha: &a)
        elevated.getWhite(&elevW, alpha: &a)
        overlay.getWhite(&overlayW, alpha: &a)

        XCTAssertLessThan(baseW, elevW, "surfaceBase should be darker than surfaceElevated")
        XCTAssertLessThan(elevW, overlayW, "surfaceElevated should be darker than surfaceOverlay")
    }

    func testTextColorsExist() {
        // These should compile and not crash
        let _ = Color.textPrimary
        let _ = Color.textSecondary
        let _ = Color.textTertiary
    }

    func testAccentVariantsExist() {
        let _ = Color.accentSubtle
        let _ = Color.accentMedium
    }

    func testStateColorsExist() {
        let _ = Color.stateSuccess
        let _ = Color.stateWarning
        let _ = Color.stateError
    }

    func testSyncStateColorsExist() {
        let _ = Color.syncInSync
        let _ = Color.syncDrifting
        let _ = Color.syncMismatched
    }

    func testSyncStateColorsMatchBaseTokens() {
        XCTAssertEqual(UIColor(Color.syncInSync), UIColor(Color.stateSuccess))
        XCTAssertEqual(UIColor(Color.syncDrifting), UIColor(Color.stateWarning))
        XCTAssertEqual(UIColor(Color.syncMismatched), UIColor(Color.stateError))
    }

    func testTextOnAccentExists() {
        let _ = Color.textOnAccent
    }

    // MARK: - Font Tokens

    func testFontTokensExist() {
        let _ = Font.displayHero
        let _ = Font.displaySecondary
        let _ = Font.heading
        let _ = Font.subheading
        let _ = Font.bodyText
        let _ = Font.bodyBold
        let _ = Font.captionText
        let _ = Font.captionBold
        let _ = Font.labelText
    }

    // MARK: - Spacing Tokens

    func testSpacingValues() {
        XCTAssertEqual(Spacing.xxs, 2)
        XCTAssertEqual(Spacing.xs, 4)
        XCTAssertEqual(Spacing.sm, 8)
        XCTAssertEqual(Spacing.md, 16)
        XCTAssertEqual(Spacing.lg, 24)
        XCTAssertEqual(Spacing.xl, 32)
        XCTAssertEqual(Spacing.xxl, 48)
    }

    // MARK: - Radius Tokens

    func testRadiusValues() {
        XCTAssertEqual(Radius.sm, 6)
        XCTAssertEqual(Radius.md, 12)
        XCTAssertEqual(Radius.lg, 20)
        XCTAssertEqual(Radius.pill, 28)
    }

    // MARK: - Component Size Tokens

    func testComponentSizeValues() {
        XCTAssertEqual(ComponentSize.miniPlayerHeight, 64)
        XCTAssertEqual(ComponentSize.buttonHeight, 52)
        XCTAssertEqual(ComponentSize.coverArtSmall, 44)
        XCTAssertEqual(ComponentSize.coverArtLarge, 200)
        XCTAssertEqual(ComponentSize.iconSmall, 24)
        XCTAssertEqual(ComponentSize.iconMedium, 44)
        XCTAssertEqual(ComponentSize.iconLarge, 60)
        XCTAssertEqual(ComponentSize.miniPlayerCollapsedHeight, 20)
        XCTAssertEqual(ComponentSize.dragHandleWidth, 36)
        XCTAssertEqual(ComponentSize.dragHandleHeight, 4)
        XCTAssertEqual(ComponentSize.dragHandleCornerRadius, 2)
    }

    // MARK: - Haptic Tokens

    func testHapticTokensExist() {
        // Each BSHaptics method should be callable without crash (no-ops on simulator)
        BSHaptics.light()
        BSHaptics.medium()
        BSHaptics.heavy()
        BSHaptics.selection()
        BSHaptics.success()
        BSHaptics.warning()
        BSHaptics.error()
    }

    // MARK: - Animation Tokens

    func testAnimationTokensExist() {
        let _ = BSAnimation.snappy
        let _ = BSAnimation.smooth
        let _ = BSAnimation.gentle
        let _ = BSAnimation.quick
        let _ = BSAnimation.page
    }
}
