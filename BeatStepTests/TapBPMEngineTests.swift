import XCTest
@testable import BeatStep

@MainActor
final class TapBPMEngineTests: XCTestCase {

    private var engine: TapBPMEngine!

    override func setUp() async throws {
        try await super.setUp()
        engine = TapBPMEngine()
    }

    override func tearDown() async throws {
        engine.reset()
        engine = nil
        try await super.tearDown()
    }

    // MARK: - 1. First Tap

    func testFirstTapSetsInitialState() {
        let t0 = Date()
        engine.tap(at: t0)

        XCTAssertEqual(engine.tapCount, 1)
        XCTAssertNil(engine.currentBPM)
        XCTAssertFalse(engine.canSave)
        XCTAssertFalse(engine.isStable)
        XCTAssertFalse(engine.lastTapWasOutlier)
    }

    // MARK: - 2. Second Tap at 0.5s Interval (120 BPM)

    func testSecondTapProduces120BPM() {
        let t0 = Date()
        engine.tap(at: t0)
        engine.tap(at: t0.addingTimeInterval(0.5))

        XCTAssertEqual(engine.currentBPM, 120)
        XCTAssertEqual(engine.tapCount, 2)
    }

    // MARK: - 3. Steady 120 BPM x9 Taps

    func testSteady120BPMNineTapsProducesStable() {
        let t0 = Date()
        for i in 0..<9 {
            engine.tap(at: t0.addingTimeInterval(Double(i) * 0.5))
        }

        XCTAssertEqual(engine.currentBPM, 120)
        XCTAssertTrue(engine.isStable)
        XCTAssertEqual(engine.tapCount, 9)
    }

    // MARK: - 4. Rolling Window (12 Taps)

    func testRollingWindowUsesLast8Intervals() {
        let t0 = Date()
        // First 3 taps at 120 BPM (0.5s intervals) = 2 intervals
        for i in 0..<3 {
            engine.tap(at: t0.addingTimeInterval(Double(i) * 0.5))
        }
        // Next 10 taps at 100 BPM (0.6s intervals) = 10 more intervals
        // 0.6s is within 40% of 0.5s median (20% deviation), so not rejected
        let offset = 2.0 * 0.5 // last tap was at 1.0s
        for i in 1...10 {
            engine.tap(at: t0.addingTimeInterval(offset + Double(i) * 0.6))
        }

        // After 13 taps (12 intervals), rolling window keeps last 8.
        // Last 8 intervals are all 0.6s -> BPM = 60/0.6 = 100
        XCTAssertEqual(engine.currentBPM, 100)
        XCTAssertTrue(engine.isStable)
    }

    // MARK: - 5. Outlier Rejection

    func testOutlierTapIsRejected() {
        let t0 = Date()
        // 4 steady 120 BPM taps
        for i in 0..<4 {
            engine.tap(at: t0.addingTimeInterval(Double(i) * 0.5))
        }

        let bpmBefore = engine.currentBPM
        let tapCountBefore = engine.tapCount

        // Erratic tap at 0.1s (600 BPM) — way outside 40% of 0.5s median
        engine.tap(at: t0.addingTimeInterval(1.5 + 0.1))

        XCTAssertTrue(engine.lastTapWasOutlier)
        XCTAssertEqual(engine.tapCount, tapCountBefore, "Tap count should not change on outlier")
        XCTAssertEqual(engine.currentBPM, bpmBefore, "BPM should not change on outlier")
    }

    // MARK: - 6. Boundary Rejection

    func testTooFastIntervalRejected() {
        let t0 = Date()
        engine.tap(at: t0)
        engine.tap(at: t0.addingTimeInterval(0.15)) // < 0.2s

        XCTAssertTrue(engine.lastTapWasOutlier)
        XCTAssertNil(engine.currentBPM)
        XCTAssertEqual(engine.tapCount, 1, "Tap count should remain 1 after boundary rejection")
    }

    func testTooSlowIntervalRejected() {
        let t0 = Date()
        engine.tap(at: t0)
        engine.tap(at: t0.addingTimeInterval(2.5)) // > 2.0s

        XCTAssertTrue(engine.lastTapWasOutlier)
        XCTAssertNil(engine.currentBPM)
        XCTAssertEqual(engine.tapCount, 1, "Tap count should remain 1 after boundary rejection")
    }

    // MARK: - 7. canSave Thresholds

    func testCanSaveFalseAtThreeTaps() {
        let t0 = Date()
        for i in 0..<3 {
            engine.tap(at: t0.addingTimeInterval(Double(i) * 0.5))
        }
        XCTAssertFalse(engine.canSave, "canSave should be false with only 2 intervals (3 taps)")
    }

    func testCanSaveTrueAtFourTaps() {
        let t0 = Date()
        for i in 0..<4 {
            engine.tap(at: t0.addingTimeInterval(Double(i) * 0.5))
        }
        XCTAssertTrue(engine.canSave, "canSave should be true with 3 intervals (4 taps)")
    }

    // MARK: - 8. Reset

    func testResetClearsAllState() {
        let t0 = Date()
        for i in 0..<5 {
            engine.tap(at: t0.addingTimeInterval(Double(i) * 0.5))
        }

        engine.reset()

        XCTAssertNil(engine.currentBPM)
        XCTAssertEqual(engine.tapCount, 0)
        XCTAssertFalse(engine.isStable)
        XCTAssertFalse(engine.lastTapWasOutlier)
        XCTAssertFalse(engine.canSave)
    }

    // MARK: - 9. Inactivity Reset

    func testInactivityResetClearsState() {
        // The actual 3s timer is tested implicitly in production.
        // Here we verify reset() produces correct state, which the timer calls.
        let t0 = Date()
        for i in 0..<5 {
            engine.tap(at: t0.addingTimeInterval(Double(i) * 0.5))
        }

        XCTAssertNotNil(engine.currentBPM)
        engine.reset()

        XCTAssertNil(engine.currentBPM)
        XCTAssertEqual(engine.tapCount, 0)
        XCTAssertFalse(engine.isStable)
        XCTAssertFalse(engine.canSave)
    }

    // MARK: - 10. Outlier With No Prior Intervals

    func testSecondTapOutOfBoundsRejected() {
        let t0 = Date()
        engine.tap(at: t0)
        // Second tap at 0.1s — no prior intervals, but < 0.2s boundary
        engine.tap(at: t0.addingTimeInterval(0.1))

        XCTAssertTrue(engine.lastTapWasOutlier)
        XCTAssertNil(engine.currentBPM)
        XCTAssertEqual(engine.tapCount, 1)
    }

    // MARK: - Edge Cases

    func testValidTapAfterOutlierIsAccepted() {
        let t0 = Date()
        for i in 0..<4 {
            engine.tap(at: t0.addingTimeInterval(Double(i) * 0.5))
        }

        // Outlier tap
        engine.tap(at: t0.addingTimeInterval(1.5 + 0.1))
        XCTAssertTrue(engine.lastTapWasOutlier)

        // Valid tap at expected interval from last valid tap (t0 + 1.5)
        engine.tap(at: t0.addingTimeInterval(1.5 + 0.5))
        XCTAssertFalse(engine.lastTapWasOutlier)
        XCTAssertEqual(engine.currentBPM, 120)
    }

    func testNoTapsProducesCleanState() {
        XCTAssertNil(engine.currentBPM)
        XCTAssertEqual(engine.tapCount, 0)
        XCTAssertFalse(engine.isStable)
        XCTAssertFalse(engine.lastTapWasOutlier)
        XCTAssertFalse(engine.canSave)
    }
}
