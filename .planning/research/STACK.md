# Stack Research

**Domain:** Native iOS running music-sync app (accelerometer cadence to Spotify BPM matching)
**Researched:** 2026-03-19
**Confidence:** MEDIUM (critical BPM data source issue discovered -- see Pitfalls)

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Swift | 6.x (Xcode 16+) | Language | Current standard. Swift concurrency (async/await, actors) is essential for managing concurrent sensor data + network + playback streams. Swift 6 strict concurrency checking catches data races at compile time. |
| SwiftUI | iOS 17+ APIs | UI framework | Declarative, reactive UI. The @Observable macro (iOS 17+) eliminates Combine boilerplate for state management. SwiftUI's lifecycle integrates cleanly with background audio modes. |
| CoreMotion | System framework | Accelerometer + pedometer | Apple's first-party framework. CMPedometer provides `currentCadence` (steps/sec) directly -- no manual signal processing needed for basic cadence. CMMotionManager gives raw accelerometer for custom peak detection if higher fidelity is needed. |
| Spotify iOS SDK (SpotifyiOS) | v5.0.1 | Playback control + auth | The only way to control Spotify playback from a third-party iOS app. SPTAppRemote handles play/pause/skip/queue. Requires Spotify app installed. Supports SPM. |
| Spotify Web API | Current | Track metadata, user library, search | REST API for fetching user playlists, searching tracks, getting track metadata. Auth via OAuth 2.0 PKCE. **Critical: Audio Features endpoint is deprecated for new apps (see below).** |

### BPM Data Strategy (Critical Decision)

**Problem:** Spotify deprecated the Audio Features API (which provided BPM/tempo) for all new apps as of November 27, 2024. New developer accounts get 403 errors. This is the single biggest technical risk for BeatStep.

**Recommended approach -- layered BPM sourcing:**

| Priority | Source | Coverage | Confidence |
|----------|--------|----------|------------|
| 1 | GetSongBPM API | Large catalog, free with attribution | MEDIUM |
| 2 | AcousticBrainz (via MusicBrainz IDs) | ~29M recordings, CC0 data, but no new data since 2022 | MEDIUM |
| 3 | On-device BPM detection (Accelerate/vDSP) | Any audio, but requires local audio access | LOW -- feasibility unclear with Spotify streaming |
| 4 | User-contributed BPM cache | Grows over time | LOW initially |

**Recommendation:** Use GetSongBPM API as primary source. Cross-reference with AcousticBrainz for validation. Cache BPM data aggressively on-device per Spotify track ID. Build the architecture so the BPM source is swappable (protocol-based abstraction). If Spotify re-opens Audio Features for certain app categories (music tools), you can slot it back in.

### Supporting Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Accelerate (vDSP) | System framework | Signal processing / FFT | Custom step detection from raw accelerometer data if CMPedometer cadence proves too laggy or imprecise for real-time beat matching. Also useful for on-device BPM detection of audio if that path is pursued. |
| KeychainAccess | Latest (SPM) | Secure token storage | Store Spotify OAuth tokens securely. Simpler API than raw Security framework. |
| SwiftData | iOS 17+ | Local persistence | Cache BPM data per track, user preferences, playlist metadata. Replaces Core Data with Swift-native API. |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| Xcode 16+ | IDE, build, debug | Required for iOS 18 SDK submission. Use Instruments for CoreMotion profiling. |
| Swift Package Manager | Dependency management | Native to Xcode. SpotifyiOS supports SPM. Avoid CocoaPods -- it's legacy. |
| Instruments (CoreMotion template) | Sensor debugging | Essential for testing accelerometer + pedometer on real devices. Simulator has no accelerometer. |
| Charles Proxy / Proxyman | Network debugging | Debug Spotify API calls, inspect OAuth flow, verify BPM API responses. |

## Architecture Patterns

### App Architecture: MVVM with @Observable

Use `@Observable` (iOS 17+) for ViewModels. No Combine pipelines needed for basic state management. Reserve Combine only for CoreMotion sensor streams where `AsyncStream` bridging is complex.

```swift
@Observable
final class RunSessionViewModel {
    var currentCadence: Double = 0
    var currentTrack: SpotifyTrack?
    var isRunning: Bool = false

    private let cadenceService: CadenceDetecting
    private let playbackService: PlaybackControlling
    private let bpmMatcher: BPMMatcher
}
```

### Concurrency Model

| Concern | Pattern | Why |
|---------|---------|-----|
| Sensor data flow | `AsyncStream<CadenceUpdate>` | Bridges CoreMotion callbacks to structured concurrency |
| Network calls | `async/await` | Native Swift concurrency for Spotify API + BPM API calls |
| State isolation | `@MainActor` on ViewModels | UI state stays on main thread, sensor processing off-main |
| Background work | `actor` for BPM cache | Thread-safe BPM database access |

### Background Execution

The app needs two background modes enabled in Info.plist:

1. **Audio** (`audio`) -- Required because Spotify playback runs through the Spotify app, but BeatStep needs to stay active to detect cadence and queue tracks. The audio background mode keeps your app process alive.
2. **Location** -- NOT needed. CoreMotion pedometer updates work in foreground. For background cadence, the audio mode is sufficient to keep the process alive.

**Important caveat:** CMPedometer `startUpdates` delivers updates only while the app is in foreground or has an active background mode. The audio background mode satisfies this requirement.

## Installation

```swift
// Package.swift dependencies (or via Xcode SPM UI)
dependencies: [
    .package(url: "https://github.com/spotify/ios-sdk.git", from: "5.0.1"),
    .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.2"),
]
```

System frameworks (no package needed):
- `CoreMotion`
- `Accelerate` (vDSP)
- `SwiftData`

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| SwiftUI + @Observable | UIKit + Combine | Never for a greenfield 2026 app. UIKit adds boilerplate with no benefit here. |
| CMPedometer (cadence) | Raw CMMotionManager + custom peak detection | If CMPedometer cadence updates are too infrequent (updates every ~1-2 sec). Raw accelerometer at 50-100Hz with vDSP peak detection gives sub-second cadence response. Start with CMPedometer, fall back to raw if needed. |
| SwiftData | Core Data | Never. SwiftData is the modern replacement, simpler API, same SQLite backing. |
| GetSongBPM API | Soundcharts API | If you need commercial-grade coverage. Soundcharts is paid but has 70M+ tracks. GetSongBPM is free with attribution. |
| SPM | CocoaPods | Never for new projects. CocoaPods is maintenance-mode. SPM is Apple-native. |
| @Observable | Combine ObservableObject | Only if targeting iOS 16 or below (you shouldn't). @Observable is cleaner and more performant. |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Spotify Audio Features API | Deprecated Nov 2024 for new apps. Returns 403. | GetSongBPM API + AcousticBrainz as BPM sources |
| Spotify Audio Analysis API | Same deprecation as Audio Features. | Same alternatives as above |
| CocoaPods | Legacy package manager, slow builds, Podfile complexity | Swift Package Manager |
| Combine for state management | @Observable makes it unnecessary for ViewModel state. Combine is over-engineered for this use case. | @Observable macro |
| RxSwift | Third-party reactive framework. Swift concurrency + @Observable covers all use cases natively now. | async/await + @Observable |
| UIKit | No benefit for a greenfield SwiftUI app. Adds bridging complexity. | SwiftUI |
| Real-time audio tempo stretching | Explicitly out of scope per PROJECT.md. Extremely complex DSP. | Queue BPM-matched tracks instead |
| React Native / Flutter | Cross-platform frameworks lack direct CoreMotion access and Spotify SDK integration quality. iOS-only per constraints. | Native Swift/SwiftUI |

## Minimum Deployment Target

**iOS 17.0** -- This gives access to:
- `@Observable` macro (eliminates Combine boilerplate)
- SwiftData (modern persistence)
- Improved SwiftUI navigation APIs
- All CoreMotion APIs needed
- Covers ~85%+ of active iPhones as of early 2026

Do NOT target iOS 16 or lower. The DX improvements of iOS 17+ APIs (especially @Observable) dramatically reduce code complexity for a reactive sensor-driven app like BeatStep.

## Version Compatibility

| Component | Compatible With | Notes |
|-----------|-----------------|-------|
| SpotifyiOS v5.0.1 | iOS 12+, arm64 | Works fine with iOS 17+ target. SPM compatible. |
| Swift 6.x | Xcode 16+ | Strict concurrency checking. Enable gradually with `-strict-concurrency=targeted` then `complete`. |
| SwiftData | iOS 17+ | Cannot be used below iOS 17. |
| @Observable | iOS 17+ | Requires `import Observation`. |
| CMPedometer.currentCadence | iOS 9+ | Available on all modern devices. |
| Accelerate/vDSP | iOS 4+ | System framework, always available. |

## Key API Constraints

### Spotify iOS SDK (SPTAppRemote)
- Requires Spotify app installed on device
- Requires Spotify Premium for playback control
- App must have active audio to stay connected in background
- Queue management: `play(uri:)` no longer clears the queue (changed ~2022) -- use `setShuffle(false)` and explicit queue management
- OAuth flow uses app-switch (opens Spotify app, returns via URL scheme)

### Spotify Web API
- Rate limits: standard tier, no published exact limits but ~30 req/sec is safe
- OAuth 2.0 with PKCE (no client secret on mobile)
- Track search, playlist access, user library -- all still available
- **Audio Features and Audio Analysis -- DEPRECATED for new apps**

### CoreMotion
- No accelerometer in Simulator -- must test on real device
- CMPedometer updates stop when app is backgrounded WITHOUT an active background mode
- `currentCadence` is in steps/second -- multiply by 60 for BPM (steps per minute)
- Updates arrive every ~1-2 seconds, not per-step

## Sources

- [Spotify iOS SDK GitHub](https://github.com/spotify/ios-sdk) -- v5.0.1, SPM support, SPTAppRemote API (HIGH confidence)
- [Spotify Developer Blog: Web API Changes Nov 2024](https://developer.spotify.com/blog/2024-11-27-changes-to-the-web-api) -- Audio Features deprecation confirmed (HIGH confidence)
- [Apple CoreMotion Documentation](https://developer.apple.com/documentation/coremotion/) -- CMPedometer, currentCadence (HIGH confidence)
- [Apple vDSP Documentation](https://developer.apple.com/documentation/accelerate/vdsp) -- FFT, signal processing (HIGH confidence)
- [GetSongBPM API](https://getsongbpm.com/api) -- BPM database alternative (MEDIUM confidence -- need to verify rate limits and coverage)
- [AcousticBrainz](https://acousticbrainz.org/) -- Open BPM data, 29M recordings, no new data since 2022 (MEDIUM confidence)
- [Swift Package Index: SpotifyiOS](https://swiftpackageindex.com/spotify/ios-sdk) -- SPM compatibility confirmed (HIGH confidence)
- [Spotify Community: Audio Features 403 errors](https://community.spotify.com/t5/Spotify-for-Developers/Web-API-Get-Track-s-Audio-Features-403-error/td-p/6654507) -- Deprecation confirmed by community reports (HIGH confidence)

---
*Stack research for: BeatStep -- iOS running cadence to Spotify BPM sync*
*Researched: 2026-03-19*
