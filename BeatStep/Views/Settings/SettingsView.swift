import CoreMotion
import HealthKit
import SwiftUI

struct SettingsView: View {
    private var authService: SpotifyAuthService { .shared }
    @AppStorage("hasRequestedHealth") private var hasRequestedHealth = false
    @AppStorage("hasRequestedMotion") private var hasRequestedMotion = false
    @AppStorage("sensorLabEnabled") private var sensorLabEnabled = false
    @State private var debugTapCount = 0

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(version) (\(build))"
    }

    var body: some View {
        List {
            // 1. Account
            if let user = authService.currentUser {
                Section {
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
                } header: {
                    Label("Account", systemImage: "person.circle")
                        .foregroundStyle(Color.accent)
                        .font(.captionBold)
                }
            }

            // 2. Run Defaults
            Section {
                NavigationLink {
                    RunDefaultsView()
                } label: {
                    Text("Running Zones & Playback")
                }
            } header: {
                Label("Run Defaults", systemImage: "figure.run")
                    .foregroundStyle(Color.accent)
                    .font(.captionBold)
            }

            // 3. Permissions
            Section {
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
            } header: {
                Label("Permissions", systemImage: "lock.shield")
                    .foregroundStyle(Color.accent)
                    .font(.captionBold)
            }

            // 4. Debug (only when enabled)
            if sensorLabEnabled {
                Section {
                    NavigationLink("Sensor Lab") {
                        SensorLabView()
                    }
                } header: {
                    Label("Debug", systemImage: "wrench.and.screwdriver")
                        .foregroundStyle(Color.accent)
                        .font(.captionBold)
                }
            }

            // 5. About
            Section {
                Text("BeatStep v\(appVersion)")
                    .font(.captionText)
                    .foregroundStyle(Color.textSecondary)
                    .frame(maxWidth: .infinity)
                    .onTapGesture {
                        debugTapCount += 1
                        if debugTapCount >= 5 {
                            sensorLabEnabled.toggle()
                            debugTapCount = 0
                        }
                    }
            } header: {
                Label("About", systemImage: "info.circle")
                    .foregroundStyle(Color.accent)
                    .font(.captionBold)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.surfaceBase)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}
