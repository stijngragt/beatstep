# Phase 1: Spotify Integration - Research

**Researched:** 2026-03-19
**Domain:** Spotify iOS SDK, Web API, SwiftUI, background audio
**Confidence:** HIGH

## Summary

BeatStep Phase 1 requires integrating two distinct Spotify interfaces: **SPTAppRemote** (iOS SDK) for playback control and **Spotify Web API** for library/playlist data. SPTAppRemote delegates all actual audio playback to the installed Spotify app running in the background -- BeatStep never plays audio directly. This means Spotify Premium is required (free accounts cannot play on-demand tracks via URI), and the Spotify app must be installed on the device.

The main architectural challenge is that SPTAppRemote must disconnect when the app backgrounds and reconnect when it foregrounds (iOS requirement), yet music continues playing because the Spotify app itself handles playback. Lock screen controls work via MPRemoteCommandCenter, and audio interruptions (phone calls) are handled via AVAudioSession notifications. Token management requires two separate token flows: SPTAppRemote provides its own access token for playback control, while the Web API needs a separate PKCE-based OAuth token for playlist data.

**Primary recommendation:** Use SPTAppRemote (via SPM) for playback, raw URLSession + async/await for Web API calls (no third-party wrapper), KeychainAccess for token storage, and SwiftUI's `.onOpenURL` for auth callbacks.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- Spotify login is an onboarding gate -- can't proceed without it
- Premium required -- check on login, block free accounts with clear message
- Silent token refresh in background; only re-show login if refresh fails
- Disconnect/logout option available in a settings screen
- Minimal controls: play/pause and skip only (no seek, volume, or back)
- Persistent mini-player bar at bottom of screen showing track name, artist, and BPM
- No full now-playing screen -- mini-player is sufficient for Phase 1
- User can start playback by tapping a track in a playlist
- Show playlists only -- no saved tracks, albums, or recently played
- Playlists displayed as vertical list with cover art, name, and track count
- Tapping a playlist shows its track list; tapping a track starts playback from that point
- Paginated loading for large playlists (100+ tracks)
- No search or filtering in Phase 1
- Lock screen controls via MPRemoteCommandCenter (play/pause/skip)
- Auto-reconnect silently if SPTAppRemote disconnects; only notify user if reconnection fails after retries
- Auto-resume playback after audio interruption (phone call, navigation voice)
- No push notifications for track changes

### Claude's Discretion
- Loading states and skeleton UI
- Exact spacing, typography, and color palette
- Error state handling and copy
- Settings screen layout beyond the disconnect button
- Onboarding screen design and copy

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| SPOT-01 | User can authenticate with Spotify via OAuth | SPTAppRemote auth flow + PKCE for Web API; `.onOpenURL` in SwiftUI; token storage in Keychain |
| SPOT-02 | User can control playback (play/pause/skip) from the app | SPTAppRemote playerAPI -- `play(uri:)`, `resume()`, `pause()`, `skip()` methods |
| SPOT-03 | Playback continues in background with lock screen controls | Spotify app handles background playback; MPRemoteCommandCenter for lock screen; AVAudioSession for interruptions |
| SPOT-04 | App can access user's Spotify playlists and saved tracks | Web API `GET /v1/me/playlists` and `GET /v1/playlists/{id}/tracks` with pagination |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SpotifyiOS (SPTAppRemote) | Latest via SPM | Playback control, auth with Spotify app | Official Spotify SDK -- the only supported way to control Spotify playback on iOS |
| Spotify Web API | v1 | Playlist data, user profile, track metadata | REST API -- only way to access library data; SPTAppRemote does not expose playlist browsing |
| KeychainAccess | Latest via SPM | Secure token storage | Simple Swift wrapper over Keychain; avoids raw Security framework boilerplate |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| URLSession (built-in) | iOS 15+ | Web API HTTP calls | All REST API calls -- no third-party HTTP library needed |
| AVFoundation (built-in) | iOS 15+ | AVAudioSession configuration | Audio session category, interruption handling |
| MediaPlayer (built-in) | iOS 15+ | MPRemoteCommandCenter, MPNowPlayingInfoCenter | Lock screen controls, now playing info |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Raw URLSession | Peter-Schorn/SpotifyAPI | Full Combine-based wrapper for all endpoints; adds significant dependency. BeatStep only needs 3 endpoints -- raw URLSession is simpler and avoids Combine dependency |
| KeychainAccess | Raw Keychain Services API | Works but verbose; KeychainAccess is lightweight and well-maintained |
| KeychainAccess | evgenyneu/keychain-swift | Similar quality; KeychainAccess has broader community adoption |

**Installation:**
```
// In Xcode: File > Add Package Dependencies
// SpotifyiOS: https://github.com/spotify/ios-sdk
// KeychainAccess: https://github.com/kishikawakatsumi/KeychainAccess
```

## Architecture Patterns

### Recommended Project Structure
```
BeatStep/
├── App/
│   ├── BeatStepApp.swift          # @main, .onOpenURL handler
│   └── ContentView.swift          # Root view with auth gate
├── Services/
│   ├── SpotifyAuthService.swift   # Auth flow, token management, premium check
│   ├── SpotifyPlayerService.swift # SPTAppRemote wrapper, playback control
│   ├── SpotifyAPIService.swift    # Web API calls (playlists, profile)
│   └── AudioSessionService.swift  # AVAudioSession + MPRemoteCommandCenter
├── Models/
│   ├── SpotifyPlaylist.swift      # Codable models for API responses
│   ├── SpotifyTrack.swift
│   └── SpotifyUser.swift
├── Views/
│   ├── Onboarding/
│   │   └── LoginView.swift        # Spotify login gate
│   ├── Library/
│   │   ├── PlaylistListView.swift # Vertical list of playlists
│   │   └── PlaylistDetailView.swift # Track list within a playlist
│   ├── Player/
│   │   └── MiniPlayerView.swift   # Persistent bottom bar
│   └── Settings/
│       └── SettingsView.swift     # Disconnect button
├── Utilities/
│   └── KeychainManager.swift      # KeychainAccess wrapper
└── Resources/
    └── Info.plist                  # URL schemes, LSApplicationQueriesSchemes
```

### Pattern 1: Dual Auth Token Management
**What:** SPTAppRemote and Web API use separate tokens. SPTAppRemote returns its own access token via the auth callback. Web API needs a PKCE-based token with broader scopes.
**When to use:** Always -- both APIs are needed simultaneously.
**Implementation approach:**
- Request auth from SPTAppRemote with additional Web API scopes
- SPTAppRemote's `authorizeAndPlayURI` opens Spotify app, which returns an access token
- Use the SPTAppRemote token for both playback control AND Web API calls (it supports additional scopes)
- Store tokens in Keychain, not UserDefaults
- Refresh token silently; on failure, clear tokens and show login

**Required scopes:**
```
app-remote-control     // SPTAppRemote playback (auto-requested)
playlist-read-private  // Read user's private playlists
playlist-read-collaborative // Include collaborative playlists
user-read-private      // Check premium status (product field)
user-read-playback-state // Read current playback state
user-read-currently-playing // Current track info
```

### Pattern 2: SwiftUI App Lifecycle with SPTAppRemote
**What:** SPTAppRemote SDK was designed for UIKit (AppDelegate/SceneDelegate). In SwiftUI with `@main App`, there is no SceneDelegate.
**When to use:** Always -- BeatStep is SwiftUI.
**Key adaptation:**

```swift
// Source: Apple Developer Forums + Spotify SDK docs
@main
struct BeatStepApp: App {
    @Environment(\.scenePhase) var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    // Handle Spotify auth callback
                    SpotifyAuthService.shared.handleCallback(url: url)
                }
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                SpotifyPlayerService.shared.connect()
            case .inactive, .background:
                SpotifyPlayerService.shared.disconnect()
            @unknown default:
                break
            }
        }
    }
}
```

### Pattern 3: Observable Service Layer
**What:** Use `@Observable` (iOS 17+) or `ObservableObject` for service classes that SwiftUI views observe.
**When to use:** SpotifyPlayerService (player state), SpotifyAuthService (auth state).
```swift
@Observable
class SpotifyPlayerService {
    var isConnected = false
    var currentTrack: SpotifyTrack?
    var isPaused = true
    // SPTAppRemote delegate updates these properties
    // SwiftUI views automatically re-render
}
```

### Pattern 4: Paginated Playlist Loading
**What:** Spotify Web API returns paginated results (max 50 items per page).
**When to use:** Playlist list and playlist tracks.
```swift
// Fetch playlists with offset-based pagination
func fetchPlaylists(offset: Int = 0, limit: Int = 50) async throws -> PaginatedResponse<SpotifyPlaylist> {
    let url = URL(string: "https://api.spotify.com/v1/me/playlists?limit=\(limit)&offset=\(offset)")!
    var request = URLRequest(url: url)
    request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    let (data, _) = try await URLSession.shared.data(for: request)
    return try JSONDecoder().decode(PaginatedResponse<SpotifyPlaylist>.self, from: data)
}
```

### Anti-Patterns to Avoid
- **Storing tokens in UserDefaults:** Insecure. Use Keychain always.
- **Calling SPTAppRemote from background threads:** SDK is NOT thread-safe. All calls must happen on main thread.
- **Trying to keep SPTAppRemote connected in background:** iOS will suspend the connection. Disconnect on background, reconnect on foreground. Music keeps playing because Spotify app handles it.
- **Building a custom audio player:** BeatStep must use SPTAppRemote. Spotify TOS prohibits custom audio engines. The Spotify app does all playback.
- **Using Implicit Grant flow:** Deprecated as of Feb 2025. PKCE is mandatory for new apps from April 2025.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Token storage | Custom encryption/file storage | KeychainAccess + iOS Keychain | Keychain is hardware-encrypted, survives app reinstalls, handles access control |
| OAuth PKCE flow | Manual code verifier/challenge generation | SPTAppRemote built-in auth (requests additional scopes) | SDK handles the app-switch auth flow and token exchange |
| Audio playback | AVAudioPlayer or custom streaming | SPTAppRemote + Spotify app | TOS requirement; Spotify handles DRM, streaming, offline, quality |
| Lock screen controls | Custom remote control handling | MPRemoteCommandCenter standard API | Apple's built-in; 5 lines of setup per command |
| HTTP networking | Alamofire or custom networking layer | URLSession async/await | Only 3 API endpoints needed; URLSession is sufficient |
| Image loading | Custom cache/download | AsyncImage (SwiftUI built-in) | Handles loading states, caching, and placeholder natively |

**Key insight:** BeatStep is a thin control layer on top of Spotify. The Spotify app does all heavy lifting (playback, streaming, DRM, offline). BeatStep's job is UI + coordination.

## Common Pitfalls

### Pitfall 1: Simulator Testing Impossible
**What goes wrong:** SPTAppRemote requires the Spotify app to be installed. Simulators cannot install App Store apps.
**Why it happens:** SPTAppRemote communicates with the Spotify app via IPC. No Spotify app = no connection.
**How to avoid:** Must test on a physical device with Spotify installed and a Premium account logged in. Web API calls can be tested in simulator, but playback cannot.
**Warning signs:** `connect()` silently fails or returns "Spotify app not installed" error.

### Pitfall 2: Token Confusion (SPTAppRemote vs Web API)
**What goes wrong:** Using the wrong token type, or not requesting sufficient scopes at auth time.
**Why it happens:** SPTAppRemote has its own token flow; Web API has PKCE. They can share a token if scopes are requested correctly during SPTAppRemote auth.
**How to avoid:** When calling `appRemote.authorizeAndPlayURI`, pass the additional Web API scopes you need. The returned token will work for both SPTAppRemote and Web API calls. Verify by checking the token scopes in the response.
**Warning signs:** 403 errors on Web API calls despite successful SPTAppRemote connection.

### Pitfall 3: Background Disconnect Surprise
**What goes wrong:** Developers expect SPTAppRemote to stay connected when backgrounded. It does not.
**Why it happens:** iOS suspends the IPC connection. The Spotify SDK docs explicitly state: "You should always disconnect App Remote when your app enters a background state."
**How to avoid:** Disconnect in `scenePhase == .background`, reconnect in `.active`. Music continues playing because the Spotify app handles playback independently.
**Warning signs:** Crash logs showing SPTAppRemote errors after backgrounding.

### Pitfall 4: App Switch Required for Initial Auth
**What goes wrong:** SPTAppRemote auth opens the Spotify app. If the user doesn't return to BeatStep, auth hangs.
**Why it happens:** `authorizeAndPlayURI` performs an app switch to Spotify for user consent. Spotify redirects back via the URL scheme.
**How to avoid:** Clear UI indicating "Opening Spotify..." and handle the case where the user doesn't return. Set a timeout or check on `sceneDidBecomeActive`.
**Warning signs:** Users stuck on "connecting" screen after declining Spotify auth.

### Pitfall 5: Audio Interruption Without Resume
**What goes wrong:** After a phone call, music doesn't resume.
**Why it happens:** AVAudioSession sends an `.ended` interruption notification, but the `shouldResume` option may not be set. Also, SPTAppRemote may have disconnected during the interruption.
**How to avoid:** Observe `AVAudioSession.interruptionNotification`. On `.ended` with `shouldResume` flag, call `playerAPI?.resume()` after reconnecting SPTAppRemote.
**Warning signs:** Users report music stopping after phone calls and not restarting.

### Pitfall 6: Free Account Silent Failure
**What goes wrong:** Free Spotify users can authenticate but playback fails with error code 9.
**Why it happens:** SPTAppRemote auth succeeds for free accounts, but playing a URI by track requires Premium.
**How to avoid:** After auth, immediately call `GET /v1/me` and check the `product` field. If not `"premium"`, show a clear blocking message before attempting any playback.
**Warning signs:** Error code 9 from SPTAppRemote: "The operation requires a Spotify Premium account."

### Pitfall 7: Info.plist Missing Configuration
**What goes wrong:** Spotify app can't redirect back to BeatStep, or BeatStep can't detect if Spotify is installed.
**Why it happens:** Missing URL scheme or `LSApplicationQueriesSchemes` in Info.plist.
**How to avoid:** Must configure both:
```xml
<key>LSApplicationQueriesSchemes</key>
<array><string>spotify</string></array>

<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLName</key>
    <string>com.beatstep.app</string>
    <key>CFBundleURLSchemes</key>
    <array><string>beatstep</string></array>
  </dict>
</array>
```
**Warning signs:** Auth flow opens Spotify but never returns to BeatStep.

## Code Examples

### SPTAppRemote Connection Manager
```swift
// Source: Spotify iOS SDK Getting Started + SceneDelegate demo
import SpotifyiOS

@Observable
class SpotifyPlayerService: NSObject, SPTAppRemoteDelegate, SPTAppRemotePlayerStateDelegate {
    static let shared = SpotifyPlayerService()

    private let clientID = "YOUR_CLIENT_ID"
    private let redirectURL = URL(string: "beatstep://spotify-callback")!

    var isConnected = false
    var currentTrack: SPTAppRemoteTrack?
    var isPaused = true

    lazy var appRemote: SPTAppRemote = {
        let config = SPTConfiguration(clientID: clientID, redirectURL: redirectURL)
        let remote = SPTAppRemote(configuration: config, logLevel: .debug)
        remote.delegate = self
        return remote
    }()

    func connect() {
        guard let token = KeychainManager.shared.accessToken else { return }
        appRemote.connectionParameters.accessToken = token
        appRemote.connect()
    }

    func disconnect() {
        if appRemote.isConnected {
            appRemote.disconnect()
        }
    }

    // MARK: - Playback Controls
    func play(uri: String) {
        appRemote.playerAPI?.play(uri, callback: defaultCallback)
    }

    func togglePlayPause() {
        if isPaused {
            appRemote.playerAPI?.resume(defaultCallback)
        } else {
            appRemote.playerAPI?.pause(defaultCallback)
        }
    }

    func skipNext() {
        appRemote.playerAPI?.skip(toNext: defaultCallback)
    }

    // MARK: - SPTAppRemoteDelegate
    func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        isConnected = true
        appRemote.playerAPI?.delegate = self
        appRemote.playerAPI?.subscribe(toPlayerState: { _, error in
            if let error { debugPrint("Subscription error: \(error)") }
        })
    }

    func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        isConnected = false
    }

    func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        isConnected = false
    }

    // MARK: - SPTAppRemotePlayerStateDelegate
    func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
        currentTrack = playerState.track
        isPaused = playerState.isPaused
    }

    private var defaultCallback: SPTAppRemoteCallback {
        { _, error in
            if let error { debugPrint("Player error: \(error)") }
        }
    }
}
```

### Web API Service (Playlists)
```swift
// Source: Spotify Web API reference
class SpotifyAPIService {
    static let shared = SpotifyAPIService()
    private let baseURL = "https://api.spotify.com/v1"

    func fetchPlaylists(offset: Int = 0, limit: Int = 50) async throws -> PaginatedResponse<SpotifyPlaylist> {
        let url = URL(string: "\(baseURL)/me/playlists?limit=\(limit)&offset=\(offset)")!
        return try await authenticatedRequest(url: url)
    }

    func fetchPlaylistTracks(playlistID: String, offset: Int = 0, limit: Int = 100) async throws -> PaginatedResponse<PlaylistTrackItem> {
        let url = URL(string: "\(baseURL)/playlists/\(playlistID)/tracks?limit=\(limit)&offset=\(offset)")!
        return try await authenticatedRequest(url: url)
    }

    func fetchCurrentUserProfile() async throws -> SpotifyUser {
        let url = URL(string: "\(baseURL)/me")!
        return try await authenticatedRequest(url: url)
    }

    private func authenticatedRequest<T: Decodable>(url: URL) async throws -> T {
        guard let token = KeychainManager.shared.accessToken else {
            throw SpotifyError.notAuthenticated
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SpotifyError.invalidResponse
        }
        if httpResponse.statusCode == 401 {
            // Token expired -- trigger refresh
            throw SpotifyError.tokenExpired
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}
```

### Premium Check After Auth
```swift
// Source: Spotify Web API /v1/me endpoint
func checkPremiumStatus() async throws -> Bool {
    let user = try await SpotifyAPIService.shared.fetchCurrentUserProfile()
    return user.product == "premium"
}

// In onboarding flow:
let isPremium = try await checkPremiumStatus()
if !isPremium {
    // Show blocking message: "BeatStep requires Spotify Premium"
    // Offer: "Upgrade on Spotify" link + "Sign in with different account"
}
```

### Lock Screen Controls
```swift
// Source: Apple Developer Documentation - MPRemoteCommandCenter
import MediaPlayer

class AudioSessionService {
    static let shared = AudioSessionService()

    func setupAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default)
        try? session.setActive(true)
    }

    func setupRemoteCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.addTarget { _ in
            SpotifyPlayerService.shared.togglePlayPause()
            return .success
        }
        commandCenter.pauseCommand.addTarget { _ in
            SpotifyPlayerService.shared.togglePlayPause()
            return .success
        }
        commandCenter.nextTrackCommand.addTarget { _ in
            SpotifyPlayerService.shared.skipNext()
            return .success
        }
        // Disable unused commands
        commandCenter.previousTrackCommand.isEnabled = false
    }

    func updateNowPlayingInfo(track: SPTAppRemoteTrack) {
        var info = [String: Any]()
        info[MPMediaItemPropertyTitle] = track.name
        info[MPMediaItemPropertyArtist] = track.artist.name
        info[MPNowPlayingInfoPropertyPlaybackRate] = 1.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    func setupInterruptionHandling() {
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { notification in
            guard let info = notification.userInfo,
                  let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

            if type == .ended {
                let options = info[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
                if AVAudioSession.InterruptionOptions(rawValue: options).contains(.shouldResume) {
                    SpotifyPlayerService.shared.connect()
                    // Resume after reconnection via delegate
                }
            }
        }
    }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Implicit Grant OAuth | PKCE OAuth (mandatory) | Feb 2025 announcement, April 2025 enforcement for new apps | All new apps MUST use PKCE |
| Spotify Audio Features API | External BPM APIs (GetSongBPM) | Nov 2024 (deprecated) | Not relevant for Phase 1 but affects Phase 2 |
| AppDelegate lifecycle | SwiftUI `@main` + `scenePhase` + `.onOpenURL` | iOS 14+ | SPTAppRemote examples still show AppDelegate; must adapt |
| UserDefaults for tokens | Keychain for tokens | Always was best practice | Security requirement |
| ObservableObject + @Published | @Observable (iOS 17) | WWDC 2023 | Simpler observation, less boilerplate |

**Deprecated/outdated:**
- Implicit Grant flow: Deprecated Feb 2025. PKCE mandatory.
- `GET /users/{id}/playlists`: Removed in Feb 2026 Web API changelog. Use `GET /v1/me/playlists` instead.
- Spotify Audio Features: Deprecated Nov 2024. Not needed for Phase 1.

## Open Questions

1. **SPTAppRemote token refresh mechanism**
   - What we know: SPTAppRemote provides an initial access token. The SDK has some built-in token refresh capability.
   - What's unclear: Exact refresh flow -- does SPTAppRemote handle refresh automatically, or must we implement PKCE refresh separately?
   - Recommendation: Implement PKCE token refresh as backup. Test SPTAppRemote's built-in refresh behavior on device. The 24-hour offline window suggests tokens need periodic refresh.

2. **SPTAppRemote + SwiftUI scenePhase timing**
   - What we know: `.onOpenURL` handles auth callback. `scenePhase` handles connect/disconnect.
   - What's unclear: Whether `scenePhase` transitions fire in the exact same order as SceneDelegate methods. Edge cases around rapid app switching.
   - Recommendation: Test on device. Add logging for scenePhase transitions. May need `UIApplicationDelegateAdaptor` as fallback.

3. **Spotify app not installed scenario**
   - What we know: `UIApplication.shared.canOpenURL(URL(string: "spotify:")!)` checks if Spotify is installed. SPTAppRemote requires it.
   - What's unclear: Best UX for directing users to install Spotify first.
   - Recommendation: Check on app launch. If not installed, show "Install Spotify" with App Store deep link before proceeding to auth.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | XCTest (built-in) + Swift Testing |
| Config file | None -- Wave 0 must create test targets |
| Quick run command | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16'` |
| Full suite command | `xcodebuild test -scheme BeatStep -destination 'platform=iOS Simulator,name=iPhone 16'` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SPOT-01 | OAuth auth flow completes, tokens stored in Keychain | unit (token storage), manual (full auth requires Spotify app) | Unit: `xcodebuild test -only-testing BeatStepTests/SpotifyAuthServiceTests` | No -- Wave 0 |
| SPOT-02 | Play/pause/skip controls work | manual-only (requires Spotify app on physical device) | N/A -- SPTAppRemote requires physical device with Spotify | No -- Wave 0 |
| SPOT-03 | Background playback + lock screen controls | manual-only (requires physical device) | N/A -- background audio + lock screen cannot be automated in XCTest | No -- Wave 0 |
| SPOT-04 | Playlists fetched and displayed | unit (API parsing, pagination) | `xcodebuild test -only-testing BeatStepTests/SpotifyAPIServiceTests` | No -- Wave 0 |

### Sampling Rate
- **Per task commit:** Unit tests for API parsing and token management
- **Per wave merge:** Full unit test suite
- **Phase gate:** Unit tests green + manual verification checklist for SPOT-02 and SPOT-03

### Wave 0 Gaps
- [ ] `BeatStepTests/` test target -- must be created in Xcode project
- [ ] `BeatStepTests/SpotifyAuthServiceTests.swift` -- token storage/retrieval, premium check parsing
- [ ] `BeatStepTests/SpotifyAPIServiceTests.swift` -- playlist JSON decoding, pagination logic, error handling
- [ ] `BeatStepTests/Mocks/MockSpotifyResponses.swift` -- JSON fixtures for API responses
- [ ] Manual test checklist for physical device verification of SPOT-02 and SPOT-03

## Sources

### Primary (HIGH confidence)
- [Spotify iOS SDK GitHub](https://github.com/spotify/ios-sdk) - README, demo projects, SceneDelegate example
- [Spotify iOS SDK Getting Started](https://developer.spotify.com/documentation/ios/getting-started) - Setup, auth flow, player API
- [Spotify iOS SDK Application Lifecycle](https://developer.spotify.com/documentation/ios/concepts/application-lifecycle) - Connect/disconnect pattern
- [Spotify Web API Scopes](https://developer.spotify.com/documentation/web-api/concepts/scopes) - All available scopes
- [Spotify Web API PKCE Flow](https://developer.spotify.com/documentation/web-api/tutorials/code-pkce-flow) - Token exchange, refresh
- [SPTScope Constants](https://spotify.github.io/ios-sdk/html/Constants/SPTScope.html) - iOS SDK scope enum values
- [Spotify Web API - Get Current User's Playlists](https://developer.spotify.com/documentation/web-api/reference/get-a-list-of-current-users-playlists) - Endpoint details, pagination
- [Spotify PKCE Security Update (Feb 2025)](https://developer.spotify.com/blog/2025-02-12-increasing-the-security-requirements-for-integrating-with-spotify) - Implicit grant deprecated
- [Apple - Handling Audio Interruptions](https://developer.apple.com/documentation/avfoundation/avaudiosession/responding_to_audio_session_interruptions) - AVAudioSession interruption pattern
- [Apple - Keychain Services](https://developer.apple.com/documentation/security/keychain-services) - Secure storage

### Secondary (MEDIUM confidence)
- [KeychainAccess GitHub](https://github.com/kishikawakatsumi/KeychainAccess) - Swift Keychain wrapper
- [Apple Developer Forums - SwiftUI URL handling](https://developer.apple.com/forums/thread/651234) - `.onOpenURL` pattern

### Tertiary (LOW confidence)
- [Medium - Spotify SwiftUI integration guide](https://medium.com/@killian.j.sonna/integrating-spotifys-api-with-swiftui-a-step-by-step-guide-f85e92985e31) - Community tutorial, may be outdated

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Official Spotify SDK is the only option; Web API endpoints are well-documented
- Architecture: HIGH - Patterns are well-established (SPTAppRemote lifecycle, URLSession, Keychain)
- Pitfalls: HIGH - Documented in official SDK docs and confirmed via multiple sources
- SwiftUI adaptation: MEDIUM - SPTAppRemote examples are UIKit-based; `.onOpenURL` + `scenePhase` pattern is standard but untested with this specific SDK

**Research date:** 2026-03-19
**Valid until:** 2026-04-19 (Spotify SDK is stable; Web API changes are documented in changelog)
