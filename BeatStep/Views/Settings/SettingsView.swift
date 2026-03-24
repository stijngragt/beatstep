import CoreMotion
import HealthKit
import SwiftUI

struct SettingsView: View {
    private var authService: SpotifyAuthService { .shared }
    @State private var zones: [RunZone] = RunZone.saved
    @AppStorage("hasRequestedHealth") private var hasRequestedHealth = false
    @AppStorage("hasRequestedMotion") private var hasRequestedMotion = false

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

            // Permissions section
            Section("Permissions") {
                HStack {
                    Text("Motion Access")
                        .foregroundStyle(Color.textSecondary)
                    Spacer()
                    Text(CMPedometer.authorizationStatus() == .authorized ? "Granted" : "Check Settings")
                        .font(.captionText)
                        .foregroundStyle(CMPedometer.authorizationStatus() == .authorized ? Color.stateSuccess : Color.stateWarning)
                }

                if HKHealthStore.isHealthDataAvailable() {
                    HStack {
                        Text("Apple Health")
                            .foregroundStyle(Color.textSecondary)
                        Spacer()
                        Text(hasRequestedHealth ? "Requested" : "Not Yet")
                            .font(.captionText)
                            .foregroundStyle(Color.textSecondary)
                    }
                }

                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
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
