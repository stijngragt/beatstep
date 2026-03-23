import SwiftUI

struct ContentView: View {
    @Environment(SpotifyAuthService.self) private var authService

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        appearance.shadowColor = .clear
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().unselectedItemTintColor = UIColor(Color.textTertiary)
    }

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
        TabView {
            NavigationStack {
                PlaylistListView()
            }
            .tabItem {
                Label("Library", systemImage: "music.note.list")
            }

            NavigationStack {
                RunTabView()
            }
            .tabItem {
                Label("Run", systemImage: "waveform.path.ecg")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
        }
        .tint(Color.accent)
        .safeAreaInset(edge: .bottom) {
            if SpotifyPlayerService.shared.currentTrack != nil {
                MiniPlayerView()
            }
        }
        .task {
            await LibraryScanService.shared.scanEnabledPlaylists()
        }
    }
}
