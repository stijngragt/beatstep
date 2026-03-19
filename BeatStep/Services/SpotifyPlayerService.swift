import Foundation
import SpotifyiOS

@Observable
class SpotifyPlayerService: NSObject {
    static let shared = SpotifyPlayerService()

    // MARK: - Observable State

    var isConnected = false
    var currentTrack: SpotifyTrack?
    var isPaused = true
    var currentTrackImageURL: String?

    // MARK: - Private

    @ObservationIgnored
    private var _appRemote: SPTAppRemote?

    private var appRemote: SPTAppRemote {
        if let existing = _appRemote { return existing }
        let configuration = SPTConfiguration(
            clientID: SpotifyAuthService.shared.clientID,
            redirectURL: SpotifyAuthService.shared.redirectURL
        )
        let remote = SPTAppRemote(configuration: configuration, logLevel: .debug)
        remote.delegate = self
        _appRemote = remote
        return remote
    }

    @ObservationIgnored
    private let defaultCallback: SPTAppRemoteCallback = { _, error in
        if let error {
            debugPrint("SpotifyPlayerService: Remote call error: \(error.localizedDescription)")
        }
    }

    private override init() {
        super.init()
    }

    // MARK: - Playback Control

    func connect() {
        guard let token = KeychainManager.shared.accessToken else {
            debugPrint("SpotifyPlayerService: No access token, cannot connect")
            return
        }

        appRemote.connectionParameters.accessToken = token

        DispatchQueue.main.async { [weak self] in
            self?.appRemote.connect()
        }
    }

    func disconnect() {
        if appRemote.isConnected {
            appRemote.disconnect()
        }
    }

    func play(uri: String) {
        appRemote.playerAPI?.play(uri, callback: defaultCallback)
    }

    func resume() {
        appRemote.playerAPI?.resume(defaultCallback)
    }

    func pause() {
        appRemote.playerAPI?.pause(defaultCallback)
    }

    func togglePlayPause() {
        if isPaused {
            resume()
        } else {
            pause()
        }
    }

    func skipNext() {
        appRemote.playerAPI?.skip(toNext: defaultCallback)
    }
}

// MARK: - SPTAppRemoteDelegate

extension SpotifyPlayerService: SPTAppRemoteDelegate {
    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        isConnected = true
        appRemote.playerAPI?.delegate = self
        appRemote.playerAPI?.subscribe(toPlayerState: defaultCallback)
        debugPrint("SpotifyPlayerService: Connected to Spotify")
    }

    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: (any Error)?) {
        isConnected = false
        debugPrint("SpotifyPlayerService: Connection failed: \(error?.localizedDescription ?? "unknown")")
    }

    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: (any Error)?) {
        isConnected = false
        debugPrint("SpotifyPlayerService: Disconnected: \(error?.localizedDescription ?? "clean")")
    }
}

// MARK: - SPTAppRemotePlayerStateDelegate

extension SpotifyPlayerService: SPTAppRemotePlayerStateDelegate {
    func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
        isPaused = playerState.isPaused

        // Convert SPTAppRemoteTrack to our SpotifyTrack model
        let remoteTrack = playerState.track
        let track = SpotifyTrack(
            id: remoteTrack.uri,
            name: remoteTrack.name,
            uri: remoteTrack.uri,
            durationMs: Int(remoteTrack.duration),
            artists: [Artist(name: remoteTrack.artist.name)],
            album: Album(name: remoteTrack.album.name, images: nil)
        )
        currentTrack = track

        // Extract image URL from track if available
        currentTrackImageURL = remoteTrack.imageIdentifier

        // Update lock screen now playing info
        AudioSessionService.shared.updateNowPlayingInfo(
            title: track.name,
            artist: track.artistName,
            duration: track.durationSeconds
        )
    }
}
