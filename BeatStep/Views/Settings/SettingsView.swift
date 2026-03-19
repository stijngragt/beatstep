import SwiftUI

struct SettingsView: View {
    private var authService: SpotifyAuthService { .shared }

    var body: some View {
        List {
            // User info section
            if let user = authService.currentUser {
                Section("Account") {
                    if let name = user.displayName {
                        HStack {
                            Text("Name")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(name)
                        }
                    }

                    HStack {
                        Text("Plan")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(user.isPremium ? "Premium" : "Free")
                    }
                }
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
    }
}
