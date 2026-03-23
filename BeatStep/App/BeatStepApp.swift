import SwiftUI
import SwiftData

@main
struct BeatStepApp: App {
    @State private var authService = SpotifyAuthService.shared
    @Environment(\.scenePhase) var scenePhase

    let container: ModelContainer

    init() {
        let schema = Schema([CachedBPM.self, ScannedPlaylist.self])
        let config = ModelConfiguration(schema: schema)
        container = try! ModelContainer(for: schema, configurations: [config])
        BPMCacheService.shared.setContainer(container)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authService)
                .onAppear {
                    for scene in UIApplication.shared.connectedScenes {
                        guard let windowScene = scene as? UIWindowScene else { continue }
                        for window in windowScene.windows {
                            window.overrideUserInterfaceStyle = .dark
                        }
                    }
                }
        }
        .modelContainer(container)
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
