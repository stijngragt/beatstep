import SwiftUI

struct ContentView: View {
    @Environment(SpotifyAuthService.self) private var authService
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    private var appState: AppState {
        AppState.resolve(hasCompletedOnboarding: hasCompletedOnboarding, isAuthenticated: authService.isAuthenticated)
    }

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
            switch appState {
            case .onboarding:
                OnboardingFlow()
            case .login:
                LoginView()
            case .authenticated:
                authenticatedView
            }
        }
        .onAppear {
            AudioSessionService.shared.setupAudioSession()
            if hasCompletedOnboarding {
                SpotifyAuthService.shared.checkExistingAuth()
            }
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
