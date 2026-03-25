import Foundation

@Observable
final class TapBPMEngine {

    private(set) var currentBPM: Int?
    private(set) var tapCount: Int = 0
    private(set) var isStable: Bool = false
    private(set) var lastTapWasOutlier: Bool = false

    var canSave: Bool { false }

    func tap() {
        tap(at: Date())
    }

    func tap(at date: Date) {
        // Stub -- tests should fail
    }

    func reset() {
        // Stub -- tests should fail
    }
}
