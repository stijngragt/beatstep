import SwiftUI

struct OnboardingSpotifyView: View {
    @Environment(SpotifyAuthService.self) private var authService
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            // Value framing
            VStack(spacing: Spacing.md) {
                Image(systemName: "music.note.list")
                    .font(.system(size: ComponentSize.iconLarge))
                    .foregroundStyle(Color.spotifyBrand)

                Text("Your Music Library")
                    .font(.heading)
                    .foregroundStyle(Color.textPrimary)

                Text("BeatStep picks songs that match your running cadence from your Spotify playlists.")
                    .font(.bodyText)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            // Error / Loading
            if authService.isCheckingAuth {
                ProgressView("Connecting...")
                    .padding()
            } else if let error = authService.authError {
                errorView(message: error)
            }

            // Connect button
            if !authService.isCheckingAuth {
                connectButton
            }

            Spacer()
                .frame(height: Spacing.xxl)
        }
        .padding(.horizontal, Spacing.xl)
        .background(Color.surfaceBase)
        .onChange(of: authService.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                onContinue()
            }
        }
    }

    // MARK: - Subviews

    private var connectButton: some View {
        Button {
            BSHaptics.light()
            authService.initiateAuth()
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: "music.note")
                Text("Connect with Spotify")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(Color.spotifyBrand)
            .foregroundStyle(Color.textOnAccent)
            .clipShape(RoundedRectangle(cornerRadius: Radius.pill))
        }
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: Spacing.md) {
            Text(message)
                .font(.bodyText)
                .foregroundStyle(Color.stateError)
                .multilineTextAlignment(.center)

            if message.contains("Premium") {
                Button("Try Different Account") {
                    BSHaptics.light()
                    authService.disconnect()
                    authService.initiateAuth()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: Radius.md)
                .fill(Color.stateError.opacity(0.08))
        )
    }
}
