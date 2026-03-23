import SwiftUI

struct PacePresetPicker: View {
    @Binding var selectedPreset: PacePreset
    @Binding var customBPM: Int

    var targetBPM: Int {
        selectedPreset.bpm ?? customBPM
    }

    var body: some View {
        VStack(spacing: 12) {
            // Preset picker
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(PacePreset.allCases) { preset in
                        presetButton(preset)
                    }
                }
                .padding(.horizontal, 4)
            }

            // Custom BPM input
            if selectedPreset == .custom {
                HStack(spacing: 16) {
                    Text("Target BPM")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))

                    Stepper(value: $customBPM, in: 120...200) {
                        Text("\(customBPM)")
                            .font(.system(.title3, design: .monospaced, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .tint(.white)
                }
                .padding(.horizontal, 8)
                .onChange(of: customBPM) { _, newValue in
                    RunMode.savedTargetBPM = newValue
                }
            }
        }
        .onChange(of: selectedPreset) { _, newValue in
            if let bpm = newValue.bpm {
                RunMode.savedTargetBPM = bpm
            }
        }
    }

    private func presetButton(_ preset: PacePreset) -> some View {
        Button {
            selectedPreset = preset
        } label: {
            VStack(spacing: 2) {
                Text(preset.displayName)
                    .font(.caption.weight(.semibold))
                if let bpm = preset.bpm {
                    Text("\(bpm)")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule().fill(
                    selectedPreset == preset
                        ? Color.white.opacity(0.25)
                        : Color.white.opacity(0.08)
                )
            )
            .foregroundStyle(
                selectedPreset == preset ? .white : .white.opacity(0.6)
            )
        }
    }
}
