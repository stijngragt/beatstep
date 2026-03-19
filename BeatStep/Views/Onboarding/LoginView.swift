import SwiftUI

struct LoginView: View {
    @Environment(SpotifyAuthService.self) private var authService

    private let spotifyGreen = Color(red: 0.114, green: 0.725, blue: 0.329)
    private let spotifyAppStoreURL = URL(string: "https://apps.apple.com/app/spotify-music-and-podcasts/id324684580")!

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Branding
            VStack(spacing: 12) {
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 60))
                    .foregroundStyle(spotifyGreen)

                Text("BeatStep")
                    .font(.system(size: 42, weight: .bold, design: .rounded))

                Text("Your music, your stride")
                    .font(.title3)
                    .foregroundStyle(.secondary)
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
        .padding(.horizontal, 32)
    }

    // MARK: - Subviews

    private var connectButton: some View {
        VStack(spacing: 16) {
            Button {
                authService.initiateAuth()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "music.note")
                    Text("Connect with Spotify")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(spotifyGreen)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 28))
            }
        }
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Text(message)
                .font(.callout)
                .foregroundStyle(.red)
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
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.red.opacity(0.08))
        )
    }
}
