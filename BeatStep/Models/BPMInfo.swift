import SwiftUI

struct BPMInfo: Equatable {
    let bpm: Int?
    let confidence: BPMConfidence?

    static let empty = BPMInfo(bpm: nil, confidence: nil)
}
