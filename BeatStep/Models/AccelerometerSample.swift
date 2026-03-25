import Foundation

struct AccelerometerSample: Identifiable {
    let id = UUID()
    let timestamp: TimeInterval
    let x: Double
    let y: Double
    let z: Double
    var magnitude: Double { sqrt(x * x + y * y + z * z) }
}
