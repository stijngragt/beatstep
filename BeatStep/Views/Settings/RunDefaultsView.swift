import SwiftUI

struct RunDefaultsView: View {
    @State private var zones: [RunZone] = RunZone.saved
    @State private var zeroBPMFallback: ZeroBPMFallback = .saved

    var body: some View {
        List {
            Section("Running Zones") {
                ForEach($zones) { $zone in
                    ZoneSettingsRow(zone: $zone)
                }

                Button("Reset to Defaults") {
                    zones = RunZone.defaults
                    RunZone.resetToDefaults()
                }
                .foregroundStyle(Color.accent)
            }

            Section("Playback") {
                Picker("No-BPM Tracks", selection: $zeroBPMFallback) {
                    ForEach(ZeroBPMFallback.allCases, id: \.self) { option in
                        Text(option.displayName).tag(option)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.surfaceBase)
        .navigationTitle("Run Defaults")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: zones) { _, newValue in
            RunZone.saveAll(newValue)
        }
        .onChange(of: zeroBPMFallback) { _, newValue in
            newValue.save()
        }
    }
}
