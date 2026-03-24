import SwiftUI

struct ZoneBandView: View {
    let targetBPM: Int
    let toleranceRange: Int
    let currentCadence: Int
    let syncQuality: SyncQuality

    /// Compute normalized position (0.0-1.0) within the zone band.
    /// Band spans 2x tolerance range on each side of targetBPM.
    static func position(cadence: Int, targetBPM: Int, toleranceRange: Int) -> Double {
        // Stub: return -1 to fail tests
        return -1.0
    }

    var body: some View {
        Text("TODO")
    }
}
