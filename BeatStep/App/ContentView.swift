import SwiftUI

struct ContentView: View {
    @Environment(SpotifyAuthService.self) private var authService

    var body: some View {
        Group {
            if authService.isAuthenticated {
                Text("BeatStep")
                    .font(.largeTitle)
                    .fontWeight(.bold)
            } else {
                LoginView()
            }
        }
    }
}
