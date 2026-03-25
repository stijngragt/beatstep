import SwiftUI

// MARK: - Color Tokens

extension Color {
    // Accent
    static let accent = Color(red: 1.0, green: 0.271, blue: 0.271)
    static var accentSubtle: Color { accent.opacity(0.15) }
    static var accentMedium: Color { accent.opacity(0.60) }

    // Brand
    static let spotifyBrand = Color(red: 0.114, green: 0.725, blue: 0.329)

    // Surfaces (dark-to-light)
    static let surfaceBase = Color(white: 0.067)
    static let surfaceElevated = Color(white: 0.098)
    static let surfaceOverlay = Color(white: 0.133)

    // Text
    static let textPrimary = Color.white
    static var textSecondary: Color { Color.white.opacity(0.55) }
    static var textTertiary: Color { Color.white.opacity(0.35) }
    static let textOnAccent = Color.white

    // State
    static let stateSuccess = Color(red: 0.20, green: 0.78, blue: 0.35)
    static let stateWarning = Color(red: 1.0, green: 0.76, blue: 0.0)
    static let stateError = Color(red: 1.0, green: 0.45, blue: 0.45)
    static let stateApproximate = Color(red: 0.35, green: 0.55, blue: 0.95)

    // Sync State (aliases for downstream run views)
    static let syncInSync = Color.stateSuccess
    static let syncDrifting = Color.stateWarning
    static let syncMismatched = Color.stateError
}

// MARK: - Font Tokens

extension Font {
    static let displayHero = Font.system(size: 52, weight: .bold, design: .rounded)
    static let displaySecondary = Font.system(size: 18, weight: .bold, design: .rounded)
    static let displaySPM = Font.system(size: 76, weight: .bold, design: .monospaced)
    static let heading = Font.system(size: 22, weight: .bold)
    static let subheading = Font.system(size: 18, weight: .semibold)
    static let bodyText = Font.system(size: 16, weight: .regular)
    static let bodyBold = Font.system(size: 16, weight: .semibold)
    static let captionText = Font.system(size: 13, weight: .regular)
    static let captionBold = Font.system(size: 13, weight: .medium)
    static let labelText = Font.system(size: 11, weight: .medium)
}

// MARK: - Spacing Tokens

enum Spacing {
    static let xxs: CGFloat = 2
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Radius Tokens

enum Radius {
    static let sm: CGFloat = 6
    static let md: CGFloat = 12
    static let lg: CGFloat = 20
    static let pill: CGFloat = 28
}

// MARK: - Component Size Tokens

enum ComponentSize {
    static let miniPlayerHeight: CGFloat = 64
    static let buttonHeight: CGFloat = 52
    static let coverArtSmall: CGFloat = 44
    static let coverArtLarge: CGFloat = 200
    static let iconSmall: CGFloat = 24
    static let iconMedium: CGFloat = 44
    static let iconLarge: CGFloat = 60
}
