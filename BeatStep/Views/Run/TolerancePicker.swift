import SwiftUI

struct TolerancePicker: View {
    @Binding var tolerance: BPMTolerance

    var body: some View {
        Picker("Tolerance", selection: $tolerance) {
            ForEach(BPMTolerance.allCases, id: \.self) { level in
                Text("\(level.displayName) (\(level.description))")
                    .tag(level)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: tolerance) { _, newValue in
            newValue.save()
        }
    }
}
