import XCTest
@testable import BeatStep

final class SensorLabServiceTests: XCTestCase {

    // MARK: - Test 1: Buffer caps at maxSamples

    func testBufferCapsAtMaxSamples() {
        let service = SensorLabService()
        XCTAssertEqual(service.maxSamples, 100)

        for i in 0..<105 {
            let sample = AccelerometerSample(
                timestamp: TimeInterval(i),
                x: Double(i),
                y: 0,
                z: 0
            )
            service.appendSample(sample)
        }

        XCTAssertEqual(service.samples.count, 100)
        // First sample should be index 5 (oldest 5 were evicted)
        XCTAssertEqual(service.samples.first?.x, 5.0)
        XCTAssertEqual(service.samples.last?.x, 104.0)
    }

    // MARK: - Test 2: updateInterval changes detectionInterval and triggers restart

    func testUpdateIntervalChangesProperty() {
        let service = SensorLabService()
        XCTAssertEqual(service.detectionInterval, 1.0)

        service.updateInterval(2.5)

        XCTAssertEqual(service.detectionInterval, 2.5)
    }

    func testUpdateIntervalWhileNotRunningDoesNotToggleRunning() {
        let service = SensorLabService()
        XCTAssertFalse(service.isRunning)

        service.updateInterval(3.0)

        XCTAssertFalse(service.isRunning)
        XCTAssertEqual(service.detectionInterval, 3.0)
    }

    // MARK: - Test 3: stopAccelerometer resets state

    func testStopAccelerometerResetsState() {
        let service = SensorLabService()
        // Simulate some state
        service.appendSample(AccelerometerSample(timestamp: 0, x: 1, y: 2, z: 3))
        service.appendSample(AccelerometerSample(timestamp: 1, x: 4, y: 5, z: 6))

        service.stopAccelerometer()

        XCTAssertFalse(service.isRunning)
        XCTAssertTrue(service.samples.isEmpty)
        XCTAssertEqual(service.accelerationX, 0)
        XCTAssertEqual(service.accelerationY, 0)
        XCTAssertEqual(service.accelerationZ, 0)
        XCTAssertEqual(service.stepCount, 0)
    }

    // MARK: - Test 4: AccelerometerSample magnitude

    func testMagnitudeComputation() {
        let sample = AccelerometerSample(timestamp: 0, x: 3, y: 4, z: 0)
        XCTAssertEqual(sample.magnitude, 5.0, accuracy: 0.001)

        let sample2 = AccelerometerSample(timestamp: 0, x: 1, y: 1, z: 1)
        XCTAssertEqual(sample2.magnitude, sqrt(3.0), accuracy: 0.001)

        let zero = AccelerometerSample(timestamp: 0, x: 0, y: 0, z: 0)
        XCTAssertEqual(zero.magnitude, 0.0)
    }

    // MARK: - Test 5: Initial state

    func testInitialState() {
        let service = SensorLabService()

        XCTAssertFalse(service.isRunning)
        XCTAssertEqual(service.accelerationX, 0)
        XCTAssertEqual(service.accelerationY, 0)
        XCTAssertEqual(service.accelerationZ, 0)
        XCTAssertEqual(service.stepCount, 0)
        XCTAssertTrue(service.samples.isEmpty)
        XCTAssertEqual(service.detectionInterval, 1.0)
    }
}
