import SwiftUI

struct LoginView: View {
    var body: some View {
        VStack(spacing: 24) {
            Text("BeatStep")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Your music, your stride")
                .font(.title3)
                .foregroundStyle(.secondary)

            Button("Connect with Spotify") {
                SpotifyAuthService.shared.initiateAuth()
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(red: 0.114, green: 0.725, blue: 0.329))
        }
        .padding()
    }
}
