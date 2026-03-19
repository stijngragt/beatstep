import AVFoundation
import MediaPlayer

final class AudioSessionService {
    static let shared = AudioSessionService()

    private init() {}

    // MARK: - Setup

    func setupAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
        } catch {
            debugPrint("AudioSessionService: Failed to configure audio session: \(error)")
        }

        setupRemoteCommands()
        setupInterruptionHandling()
    }

    // MARK: - Remote Commands

    private func setupRemoteCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.addTarget { _ in
            SpotifyPlayerService.shared.resume()
            return .success
        }

        commandCenter.pauseCommand.addTarget { _ in
            SpotifyPlayerService.shared.pause()
            return .success
        }

        commandCenter.nextTrackCommand.addTarget { _ in
            SpotifyPlayerService.shared.skipNext()
            return .success
        }

        // Disable previous track -- BeatStep only skips forward
        commandCenter.previousTrackCommand.isEnabled = false
    }

    // MARK: - Now Playing Info

    func updateNowPlayingInfo(title: String, artist: String, duration: TimeInterval) {
        var info = [String: Any]()
        info[MPMediaItemPropertyTitle] = title
        info[MPMediaItemPropertyArtist] = artist
        info[MPMediaItemPropertyPlaybackDuration] = duration
        info[MPNowPlayingInfoPropertyPlaybackRate] = 1.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    // MARK: - Interruption Handling

    private func setupInterruptionHandling() {
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { notification in
            guard let info = notification.userInfo,
                  let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
                return
            }

            if type == .ended {
                let options = info[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
                if AVAudioSession.InterruptionOptions(rawValue: options).contains(.shouldResume) {
                    // Reconnect and resume playback after interruption (e.g., phone call ended)
                    SpotifyPlayerService.shared.connect()
                }
            }
        }
    }
}
