import SwiftUI

// MARK: - Animation Preset Tokens

enum BSAnimation {
    /// Interactive taps -- snappy with moderate bounce
    static let snappy: Animation = .spring(response: 0.3, dampingFraction: 0.7)

    /// Content transitions -- smooth with minimal overshoot
    static let smooth: Animation = .spring(response: 0.45, dampingFraction: 0.85)

    /// Background movements -- gentle ease
    static let gentle: Animation = .easeInOut(duration: 0.3)

    /// Micro-interactions -- fast settle
    static let quick: Animation = .easeOut(duration: 0.15)

    /// Page transitions -- controlled with near-critical damping
    static let page: Animation = .spring(response: 0.5, dampingFraction: 0.9)
}
