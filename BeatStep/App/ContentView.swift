import SwiftUI

enum Tab: Hashable {
    case library
    case run
    case settings
}

// MARK: - Selected Tab Environment Key

private struct SelectedTabKey: EnvironmentKey {
    static let defaultValue: Binding<Tab> = .constant(.run)
}

extension EnvironmentValues {
    var selectedTab: Binding<Tab> {
        get { self[SelectedTabKey.self] }
        set { self[SelectedTabKey.self] = newValue }
    }
}

struct ContentView: View {
    @Environment(SpotifyAuthService.self) private var authService
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var selectedTab: Tab = .run

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
        TabView(selection: $selectedTab) {
            NavigationStack {
                PlaylistListView()
            }
            .environment(\.selectedTab, $selectedTab)
            .tag(Tab.library)
            .tabItem {
                Label("Library", systemImage: "music.note.list")
            }

            NavigationStack {
                RunTabView(selectedTab: $selectedTab)
            }
            .tag(Tab.run)
            .tabItem {
                Label("Run", systemImage: "waveform.path.ecg")
            }

            NavigationStack {
                SettingsView()
            }
            .tag(Tab.settings)
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
        }
        .tint(Color.accent)
        .safeAreaInset(edge: .bottom) {
            if SpotifyPlayerService.shared.currentTrack != nil && !RunEngineService.shared.isRunActive {
                MiniPlayerView()
                    .transition(.opacity)
            }
        }
        .animation(BSAnimation.smooth, value: SpotifyPlayerService.shared.currentTrack != nil)
        .task {
            await LibraryScanService.shared.scanEnabledPlaylists()
        }
    }
}
