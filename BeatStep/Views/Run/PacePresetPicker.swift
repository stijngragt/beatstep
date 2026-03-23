import SwiftUI

struct PacePresetPicker: View {
    @Binding var selectedPreset: PacePreset
    @Binding var customBPM: Int

    var targetBPM: Int {
        selectedPreset.bpm ?? customBPM
    }

    var body: some View {
        VStack(spacing: Spacing.md) {
            // Preset picker
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.sm) {
                    ForEach(PacePreset.allCases) { preset in
                        presetButton(preset)
                    }
                }
                .padding(.horizontal, Spacing.xs)
            }

            // Custom BPM input
            if selectedPreset == .custom {
                HStack(spacing: Spacing.md) {
                    Text("Target BPM")
                        .font(.captionText)
                        .foregroundStyle(Color.textSecondary)

                    Stepper(value: $customBPM, in: 120...200) {
                        Text("\(customBPM)")
                            .font(.subheading)
                            .foregroundStyle(Color.textPrimary)
                    }
                    .tint(Color.textPrimary)
                }
                .padding(.horizontal, Spacing.sm)
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
            VStack(spacing: Spacing.xxs) {
                Text(preset.displayName)
                    .font(.captionBold)
                if let bpm = preset.bpm {
                    Text("\(bpm)")
                        .font(.labelText)
                        .foregroundStyle(Color.textSecondary)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(
                Capsule().fill(
                    selectedPreset == preset
                        ? Color.surfaceOverlay
                        : Color.surfaceElevated
                )
            )
            .foregroundStyle(
                selectedPreset == preset ? Color.textPrimary : Color.textSecondary
            )
        }
    }
}
