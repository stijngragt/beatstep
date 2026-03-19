import SwiftUI

@main
struct BeatStepApp: App {
    @State private var authService = SpotifyAuthService.shared
    @Environment(\.scenePhase) var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authService)
                .onOpenURL { url in
                    SpotifyAuthService.shared.handleCallback(url: url)
                }
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                SpotifyPlayerService.shared.connect()
            case .background:
                SpotifyPlayerService.shared.disconnect()
            default:
                break
            }
        }
    }
}
