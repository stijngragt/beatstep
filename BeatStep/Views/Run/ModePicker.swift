import SwiftUI

struct ModePicker: View {
    @Binding var mode: RunMode

    var body: some View {
        Picker("Mode", selection: $mode) {
            ForEach(RunMode.allCases, id: \.self) { runMode in
                Text(runMode.displayName)
                    .tag(runMode)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: mode) { _, newValue in
            newValue.save()
        }
    }
}
