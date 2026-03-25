import XCTest
@testable import BeatStep

@MainActor
final class CadenceServiceTests: XCTestCase {

    private var service: CadenceService!

    override func setUp() async throws {
        try await super.setUp()
        service = CadenceService.shared
        // Ensure clean state before each test
        service.stopDetecting()
    }

    override func tearDown() async throws {
        service.stopDetecting()
        service = nil
        try await super.tearDown()
    }

    // MARK: - Initial State

    func testInitialStateIsIdleWithZeroSPMAndSteadyTrend() {
        XCTAssertEqual(service.state, .idle)
        XCTAssertEqual(service.currentSPM, 0)
        XCTAssertEqual(service.trend, .steady)
    }

    // MARK: - Single Sample Processing

    func testSingleCadenceSampleProducesCorrectSPM() {
        // 2.8 steps/sec * 60 = 168 SPM
        let spm = 2.8 * 60.0  // 168
        service.state = .detecting
        service.processCadenceSample(spm, at: Date())
        XCTAssertEqual(service.currentSPM, 168)
    }

    // MARK: - Rolling Average

    func testRollingAverageOfMultipleSamples() {
        // [2.5, 2.8, 3.0] steps/sec -> [150, 168, 180] SPM -> avg = 166
        let now = Date()
        service.state = .detecting
        service.processCadenceSample(150.0, at: now)
        service.processCadenceSample(168.0, at: now.addingTimeInterval(1))
        service.processCadenceSample(180.0, at: now.addingTimeInterval(2))

        let expectedAvg = (150.0 + 168.0 + 180.0) / 3.0  // 166.0
        XCTAssertEqual(service.currentSPM, Int(expectedAvg.rounded()))
    }

    // MARK: - Window Pruning

    func testSamplesOlderThanWindowArePruned() {
        let now = Date()
        service.state = .detecting

        // Add a sample that will be 6 seconds old when we add the last one
        service.processCadenceSample(150.0, at: now.addingTimeInterval(-6))
        // Add a recent sample
        service.processCadenceSample(180.0, at: now)

        // The old sample (150) should be pruned, leaving only 180
        XCTAssertEqual(service.currentSPM, 180)
    }

    // MARK: - State Transitions

    func testTransitionFromDetectingToActiveOnFirstSample() {
        service.state = .detecting
        service.processCadenceSample(168.0, at: Date())
        XCTAssertEqual(service.state, .active)
    }

    // MARK: - Trend Detection

    func testTrendIsSteadyWhenChangesWithinThreshold() {
        let now = Date()
        service.state = .detecting

        // Feed samples that are close together (within 5 SPM)
        for i in 0..<5 {
            service.processCadenceSample(170.0 + Double(i), at: now.addingTimeInterval(Double(i)))
        }

        XCTAssertEqual(service.trend, .steady)
    }

    func testTrendIsSpeedingUpWhenCadenceIncreasesConsistently() {
        let now = Date()
        service.state = .detecting

        // Feed consistently increasing samples (>5 SPM delta)
        let samples: [Double] = [160, 163, 166, 169, 172]
        for (i, spm) in samples.enumerated() {
            service.processCadenceSample(spm, at: now.addingTimeInterval(Double(i)))
        }

        XCTAssertEqual(service.trend, .speedingUp)
    }

    func testTrendIsSlowingDownWhenCadenceDecreasesConsistently() {
        let now = Date()
        service.state = .detecting

        // Feed consistently decreasing samples (>5 SPM delta)
        let samples: [Double] = [180, 177, 174, 171, 168]
        for (i, spm) in samples.enumerated() {
            service.processCadenceSample(spm, at: now.addingTimeInterval(Double(i)))
        }

        XCTAssertEqual(service.trend, .slowingDown)
    }

    // MARK: - Stop / Reset

    func testStopDetectingResetsAllState() {
        service.state = .detecting
        service.processCadenceSample(168.0, at: Date())
        XCTAssertEqual(service.state, .active)
        XCTAssertNotEqual(service.currentSPM, 0)

        service.stopDetecting()

        XCTAssertEqual(service.state, .idle)
        XCTAssertEqual(service.currentSPM, 0)
        XCTAssertEqual(service.trend, .steady)
        XCTAssertEqual(service.stepCount, 0)
    }

    // MARK: - Step Count

    func testStepCountInitiallyZero() {
        XCTAssertEqual(service.stepCount, 0)
    }

    func testStepCountResetsOnStop() {
        // stopDetecting should reset stepCount to 0 regardless of prior state
        service.stopDetecting()
        XCTAssertEqual(service.stepCount, 0)
    }
}
