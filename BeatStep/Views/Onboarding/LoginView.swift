import SwiftUI

struct LoginView: View {
    @Environment(SpotifyAuthService.self) private var authService

    private let spotifyAppStoreURL = URL(string: "https://apps.apple.com/app/spotify-music-and-podcasts/id324684580")!

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            // Branding
            VStack(spacing: Spacing.md) {
                Text("BEATSTEP")
                    .font(.system(size: 52, weight: .bold))
                    .tracking(8)
                    .foregroundStyle(Color.textPrimary)

                Text("Your music, your stride")
                    .font(.subheading)
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer()

            // Error / State Display
            if authService.isCheckingAuth {
                ProgressView("Checking your account...")
                    .padding()
            } else if let error = authService.authError {
                errorView(message: error)
            }

            // Connect Button
            if !authService.isCheckingAuth {
                connectButton
            }

            Spacer()
                .frame(height: 40)
        }
        .padding(.horizontal, Spacing.xl)
    }

    // MARK: - Subviews

    private var connectButton: some View {
        VStack(spacing: Spacing.md) {
            Button {
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
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: Spacing.md) {
            Text(message)
                .font(.bodyText)
                .foregroundStyle(Color.stateError)
                .multilineTextAlignment(.center)

            if message.contains("install Spotify") || message.contains("Install Spotify") {
                Button("Install Spotify") {
                    UIApplication.shared.open(spotifyAppStoreURL)
                }
                .buttonStyle(.bordered)
            }

            if message.contains("Premium") {
                Button("Try Different Account") {
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
