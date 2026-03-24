import SwiftUI

struct SettingsView: View {
    private var authService: SpotifyAuthService { .shared }
    @State private var zones: [RunZone] = RunZone.saved

    var body: some View {
        List {
            // User info section
            if let user = authService.currentUser {
                Section("Account") {
                    if let name = user.displayName {
                        HStack {
                            Text("Name")
                                .foregroundStyle(Color.textSecondary)
                            Spacer()
                            Text(name)
                        }
                    }

                    HStack {
                        Text("Plan")
                            .foregroundStyle(Color.textSecondary)
                        Spacer()
                        Text(user.isPremium ? "Premium" : "Free")
                    }
                }
            }

            // Running Zones section
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

            // Disconnect section
            Section {
                Button(role: .destructive) {
                    SpotifyPlayerService.shared.disconnect()
                    SpotifyAuthService.shared.disconnect()
                } label: {
                    HStack {
                        Spacer()
                        Text("Disconnect Spotify")
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: zones) { _, newValue in
            RunZone.saveAll(newValue)
        }
    }
}
