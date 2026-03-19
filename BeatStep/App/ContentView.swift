import SwiftUI

struct ContentView: View {
    @Environment(SpotifyAuthService.self) private var authService

    var body: some View {
        Group {
            if authService.isAuthenticated {
                authenticatedView
            } else {
                LoginView()
            }
        }
        .onAppear {
            AudioSessionService.shared.setupAudioSession()
            SpotifyAuthService.shared.checkExistingAuth()
        }
    }

    // MARK: - Authenticated View

    private var authenticatedView: some View {
        ZStack(alignment: .bottom) {
            NavigationStack {
                PlaylistListView()
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            NavigationLink {
                                SettingsView()
                            } label: {
                                Image(systemName: "gearshape")
                            }
                        }
                    }
            }
            .safeAreaInset(edge: .bottom) {
                // Reserve space for mini-player so content scrolls above it
                if SpotifyPlayerService.shared.currentTrack != nil {
                    Color.clear.frame(height: 64)
                }
            }

            // Mini-player overlay at bottom
            MiniPlayerView()
        }
    }
}
