import Foundation
import CoreMotion

@Observable
final class SensorLabService {
    static let shared = SensorLabService()

    // MARK: - Observable State

    var accelerationX: Double = 0
    var accelerationY: Double = 0
    var accelerationZ: Double = 0
    var isRunning: Bool = false
    var detectionInterval: TimeInterval = 1.0
    var samples: [AccelerometerSample] = []

    // MARK: - Private

    @ObservationIgnored
    private var motionManager: CMMotionManager?
    @ObservationIgnored
    let maxSamples = 100

    // Internal init for testing; production uses .shared
    init() {}

    // MARK: - Lifecycle

    func startAccelerometer() {
        if motionManager == nil { motionManager = CMMotionManager() }
        motionManager?.accelerometerUpdateInterval = detectionInterval
        motionManager?.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let self, let data else { return }
            self.accelerationX = data.acceleration.x
            self.accelerationY = data.acceleration.y
            self.accelerationZ = data.acceleration.z
            self.appendSample(data)
        }
        isRunning = true
    }

    func stopAccelerometer() {
        motionManager?.stopAccelerometerUpdates()
        motionManager = nil
        isRunning = false
        samples.removeAll()
        accelerationX = 0
        accelerationY = 0
        accelerationZ = 0
    }

    func updateInterval(_ newInterval: TimeInterval) {
        detectionInterval = newInterval
        if isRunning {
            stopAccelerometer()
            startAccelerometer()
        }
    }

    // MARK: - Internal (testable)

    func appendSample(_ data: CMAccelerometerData) {
        let sample = AccelerometerSample(
            timestamp: data.timestamp,
            x: data.acceleration.x,
            y: data.acceleration.y,
            z: data.acceleration.z
        )
        appendSample(sample)
    }

    func appendSample(_ sample: AccelerometerSample) {
        samples.append(sample)
        if samples.count > maxSamples {
            samples.removeFirst(samples.count - maxSamples)
        }
    }
}
