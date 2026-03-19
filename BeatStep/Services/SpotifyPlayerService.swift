import Foundation

/// Stub for SpotifyPlayerService. Full implementation in Plan 02.
@Observable
class SpotifyPlayerService {
    static let shared = SpotifyPlayerService()

    var isConnected = false
    var currentTrack: SpotifyTrack?
    var isPaused = true

    private init() {}

    func connect() {}
    func disconnect() {}
    func resume() {}
    func pause() {}
    func skipNext() {}
    func play(uri: String) {}
}
