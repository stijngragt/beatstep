import SwiftUI

struct TolerancePicker: View {
    @Binding var tolerance: BPMTolerance

    var body: some View {
        VStack(spacing: Spacing.xxs) {
            Text("BPM Tolerance")
                .font(.captionText)
                .foregroundStyle(Color.textSecondary)

            Picker("Tolerance", selection: $tolerance) {
                ForEach(BPMTolerance.allCases, id: \.self) { level in
                    Text(level.displayName)
                        .tag(level)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: tolerance) { _, newValue in
                newValue.save()
            }
        }
    }
}
