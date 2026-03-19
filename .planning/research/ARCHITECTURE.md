# Architecture Research

**Domain:** iOS cadence-to-music sync running app
**Researched:** 2026-03-19
**Confidence:** MEDIUM

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        Presentation Layer                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐           │
│  │  Run Screen  │  │ Library Mgmt │  │  Settings    │           │
│  │  (SwiftUI)   │  │  (SwiftUI)   │  │  (SwiftUI)   │           │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘           │
├─────────┴──────────────────┴──────────────────┴──────────────────┤
│                        Service Layer                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐           │
│  │   Cadence    │  │    Song      │  │   Playback   │           │
│  │   Engine     │  │   Matcher    │  │   Controller │           │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘           │
├─────────┴──────────────────┴──────────────────┴──────────────────┤
│                        Integration Layer                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐           │
│  │  CoreMotion  │  │  Spotify     │  │    BPM       │           │
│  │  Adapter     │  │  Adapter     │  │    Store     │           │
│  └──────────────┘  └──────────────┘  └──────────────┘           │
├─────────────────────────────────────────────────────────────────┤
│                        Data Layer                                │
│  ┌──────────────┐  ┌──────────────┐                              │
│  │  SwiftData   │  │  Keychain    │                              │
│  │  (BPM cache) │  │  (tokens)    │                              │
│  └──────────────┘  └──────────────┘                              │
└─────────────────────────────────────────────────────────────────┘

External:
  ┌──────────────┐     ┌──────────────┐
  │ iPhone       │     │ Spotify App  │
  │ Sensors      │     │ (playback)   │
  │ (accel/gyro) │     │ + Web API    │
  └──────────────┘     └──────────────┘
```

### Component Responsibilities

| Component | Responsibility | Typical Implementation |
|-----------|----------------|------------------------|
| Cadence Engine | Detect footstrikes, compute running BPM in real-time | CoreMotion CMPedometer + optional raw accelerometer fallback |
| Song Matcher | Match cadence BPM to available songs, respect tolerance, handle half/double time | Pure Swift logic operating on BPM cache |
| Playback Controller | Orchestrate what plays next, handle transitions, manage run session state | Coordinates between Song Matcher output and Spotify Adapter |
| CoreMotion Adapter | Abstract sensor access, handle permissions, background lifecycle | Wraps CMPedometer and CMMotionManager behind protocol |
| Spotify Adapter | Abstract all Spotify communication (auth, playback control, metadata) | Wraps SPTAppRemote + Spotify Web API behind protocol |
| BPM Store | Cache track BPM data so matching is instant | SwiftData or Core Data with pre-analyzed BPM per track |

## Critical Architecture Decision: BPM Data Source

**IMPORTANT: Spotify's Audio Features API (which provided BPM/tempo data) was deprecated in November 2024 for all new applications.** New apps cannot access the `GET /audio-features` endpoint. This is the single most impactful constraint on this project's architecture.

### BPM Acquisition Strategy (ordered by recommendation)

1. **On-device BPM analysis** (RECOMMENDED) -- Use a library like Superpowered SDK or a custom FFT-based beat detection algorithm to analyze audio and extract BPM locally. This is how TrailMix and similar apps work. Requires access to audio samples, which is complex when Spotify controls playback.

2. **Community BPM databases** -- Services like GetSongBPM.com or MusicBrainz have crowd-sourced BPM data for many popular tracks. Use as a lookup/cache layer.

3. **User-assisted tagging** -- Let users tap-to-BPM or confirm/correct detected BPM values. Builds a local database over time.

4. **Hybrid approach** (MOST PRACTICAL) -- Combine community database lookup with user correction. Pre-fetch BPM data when users add playlists, cache locally. Fall back to tap-to-BPM for unknown tracks.

**Why not on-device analysis of Spotify streams:** Spotify's iOS SDK offloads all playback to the Spotify app. Your app never receives raw audio samples. You cannot pipe Spotify audio through a BPM detector. The only way to do on-device BPM analysis would be via the microphone, which is unreliable and power-hungry during a run.

## Recommended Project Structure

```
BeatStep/
├── App/                        # App entry point, configuration
│   ├── BeatStepApp.swift       # @main, dependency injection root
│   └── AppState.swift          # Global app state (run active, auth status)
├── Features/                   # Feature modules (SwiftUI views + view models)
│   ├── Run/                    # Active run experience
│   │   ├── RunView.swift       # Main run screen
│   │   ├── RunViewModel.swift  # Coordinates cadence + playback
│   │   └── CadenceDisplay.swift
│   ├── Library/                # Song pool management
│   │   ├── LibraryView.swift
│   │   └── LibraryViewModel.swift
│   └── Settings/               # BPM tolerance, mode selection
│       ├── SettingsView.swift
│       └── SettingsViewModel.swift
├── Services/                   # Business logic (no UI dependency)
│   ├── CadenceEngine/          # Step detection + BPM calculation
│   │   ├── CadenceEngine.swift         # Protocol
│   │   ├── PedometerCadenceEngine.swift # CMPedometer implementation
│   │   └── CadenceSmoothing.swift       # Rolling average, spike filtering
│   ├── SongMatcher/            # BPM matching algorithm
│   │   ├── SongMatcher.swift           # Protocol
│   │   ├── BPMMatcher.swift            # Core matching logic
│   │   └── HarmonicMatcher.swift       # Half/double time handling
│   └── PlaybackController/     # Run session orchestration
│       ├── PlaybackController.swift
│       └── TransitionStrategy.swift     # When/how to switch tracks
├── Adapters/                   # External service wrappers (protocol-based)
│   ├── Spotify/
│   │   ├── SpotifyAdapter.swift        # Protocol
│   │   ├── SpotifyAppRemote.swift      # SPTAppRemote wrapper
│   │   ├── SpotifyWebAPI.swift         # REST API calls
│   │   └── SpotifyAuth.swift           # OAuth flow
│   └── Motion/
│       ├── MotionAdapter.swift         # Protocol
│       └── CoreMotionAdapter.swift     # CMPedometer + CMMotionManager
├── Data/                       # Persistence
│   ├── Models/
│   │   ├── CachedTrack.swift           # Track + BPM cache
│   │   └── RunSession.swift            # Minimal session data
│   ├── BPMStore.swift                  # BPM lookup + cache
│   └── TokenStore.swift                # Keychain wrapper for OAuth
└── Shared/                     # Utilities, extensions
    ├── BPMUtils.swift                  # BPM math (harmonic matching, rounding)
    └── Protocols.swift                 # Shared protocol definitions
```

### Structure Rationale

- **Features/:** Organized by screen/feature, each with its own View + ViewModel. Keeps UI concerns isolated.
- **Services/:** Pure business logic with no UIKit/SwiftUI imports. Testable in isolation. Protocol-first design for easy mocking.
- **Adapters/:** All external dependencies behind protocols. CoreMotion and Spotify are wrapped so the service layer never touches frameworks directly. This is critical for testability (you cannot run CoreMotion in the simulator).
- **Data/:** Single source of truth for persistence. BPM cache is the most important data store in the app.

## Architectural Patterns

### Pattern 1: Protocol-First Adapters

**What:** Every external dependency (CoreMotion, Spotify SDK, network) is accessed through a Swift protocol. Concrete implementations wrap the real SDK.
**When to use:** Always, for every external dependency in this app.
**Trade-offs:** Slight indirection overhead, but enables testing without real sensors/Spotify and allows swapping implementations.

**Example:**
```swift
protocol CadenceProviding {
    var cadenceUpdates: AsyncStream<Double> { get }  // BPM
    func startTracking() async throws
    func stopTracking()
}

final class PedometerCadenceProvider: CadenceProviding {
    private let pedometer = CMPedometer()

    var cadenceUpdates: AsyncStream<Double> {
        AsyncStream { continuation in
            pedometer.startUpdates(from: Date()) { data, error in
                guard let cadence = data?.currentCadence?.doubleValue else { return }
                let bpm = cadence * 60.0  // steps/sec -> steps/min
                continuation.yield(bpm)
            }
        }
    }
}

// For tests / simulator:
final class MockCadenceProvider: CadenceProviding {
    var cadenceUpdates: AsyncStream<Double> {
        // Emit test values
    }
}
```

### Pattern 2: Reactive Cadence Pipeline

**What:** Cadence data flows as an async stream through a pipeline: raw sensor -> smoothing -> BPM calculation -> song matching trigger. Each stage is composable.
**When to use:** For the real-time cadence-to-music data flow.
**Trade-offs:** AsyncStream/Combine adds complexity vs. simple polling, but the reactive model naturally handles the continuous, time-varying nature of cadence data.

**Example:**
```swift
// RunViewModel orchestrates the pipeline
func startRun() async {
    for await rawBPM in cadenceEngine.cadenceUpdates {
        let smoothedBPM = smoother.smooth(rawBPM)

        // Only trigger song change if BPM shifted significantly
        if abs(smoothedBPM - currentTargetBPM) > tolerance {
            currentTargetBPM = smoothedBPM
            if let nextTrack = songMatcher.bestMatch(for: smoothedBPM) {
                await playbackController.queueTrack(nextTrack)
            }
        }
    }
}
```

### Pattern 3: Layered Spotify Integration

**What:** Use both Spotify iOS SDK (App Remote) for playback control AND Spotify Web API for metadata/search. They serve different purposes and have different auth flows.
**When to use:** This dual approach is required -- App Remote controls the Spotify app's player, Web API provides track search, user library access, and queue management.
**Trade-offs:** Two integration surfaces means more auth complexity, but each API does what the other cannot.

**Integration split:**
- **App Remote (SPTAppRemote):** Play URI, pause, resume, skip, get current track info, subscribe to player state changes
- **Web API (REST):** Search tracks, get user playlists/saved tracks, add to queue, get user profile

## Data Flow

### Core Run Loop

```
iPhone Accelerometer
    |
    v
CMPedometer (currentCadence: steps/sec)
    |
    v
CadenceEngine (convert to BPM, apply smoothing)
    |  Emits: smoothed BPM every ~2-3 seconds
    v
RunViewModel (compare to current track BPM)
    |  If delta > tolerance threshold
    v
SongMatcher (query BPM cache for best match)
    |  Considers: exact match, half-time, double-time
    |  Filters: recently played, user preferences
    v
PlaybackController (queue next track)
    |
    v
SpotifyAdapter --> Spotify App (plays audio)
```

### BPM Cache Population Flow

```
User adds playlist in Library screen
    |
    v
SpotifyWebAPI.getPlaylistTracks()
    |  Returns: track URIs, names, artists
    v
BPMStore.lookupBPM(trackURIs)
    |  Check local cache first
    |  For misses: query community BPM database
    |  For remaining misses: mark as "unknown"
    v
SwiftData (persist BPM cache)
    |
    v
User can tap-to-BPM for unknown tracks
```

### Authentication Flow

```
App Launch
    |
    v
Check Keychain for stored tokens
    |
    ├── Valid token found --> Connected state
    |
    └── No token / expired
        |
        v
    SPTAppRemote.authorizeAndPlayURI("")
        |  Opens Spotify app for OAuth consent
        v
    Callback URL with auth code
        |
        v
    Exchange for access + refresh tokens
        |
        v
    Store in Keychain --> Connected state
```

### Key Data Flows

1. **Cadence-to-music loop:** Continuous during a run. Sensor data (every ~2-3 sec from CMPedometer) flows through smoothing, triggers song matching when BPM change exceeds tolerance, queues next track via Spotify. This is the core product loop.

2. **Library sync:** User-initiated. Fetches user's Spotify playlists/saved tracks, looks up BPM for each track, caches locally. Must happen before first run so the matcher has data to work with.

3. **Playback state sync:** Bidirectional. App sends play/queue commands to Spotify. Spotify player state changes (track ended, user skipped) flow back via App Remote delegate callbacks. App must stay in sync with what Spotify is actually doing.

## Background Execution Strategy

This is the hardest architectural challenge. The app must keep cadence detection AND Spotify playback control active while the phone is in the runner's pocket (screen off, app backgrounded).

### The Constraint

iOS does not have a general-purpose "keep my app running in background" API. CoreMotion pedometer updates stop when the app is backgrounded. There is no CoreMotion-specific background mode.

### The Solution: Audio Background Mode

**Use the `audio` background mode.** Since the Spotify app handles actual audio playback, this needs careful handling:

1. **Register for `audio` background mode** in Info.plist -- this keeps your app process alive while "playing audio."
2. **Play a silent audio track** via AVAudioSession when the run starts. This is a well-established pattern used by fitness apps. A silent/near-silent audio loop keeps the app alive in background.
3. **CMPedometer continues to deliver updates** as long as your app process is alive and the pedometer was started while in the foreground.
4. **Spotify App Remote communication continues** because both apps are running and your app process hasn't been suspended.

**Alternatively, use the `location` background mode** if your app also shows the running route or uses GPS for any purpose. Location updates keep the app alive. However, Apple may reject apps that use location background mode without a legitimate location feature.

### Background Architecture

```
┌─────────────────────────────────────┐
│         BeatStep App Process         │
│                                      │
│  AVAudioSession (silent audio)       │ <-- Keeps process alive
│  CMPedometer (cadence updates)       │ <-- Continues delivering
│  SPTAppRemote (connected to Spotify) │ <-- Sends play/queue cmds
│                                      │
└────────────────┬────────────────────┘
                 │ IPC
                 v
┌─────────────────────────────────────┐
│         Spotify App Process          │
│                                      │
│  Audio playback (user hears music)   │
│  Networking, caching, etc.           │
│                                      │
└─────────────────────────────────────┘
```

## Anti-Patterns

### Anti-Pattern 1: Raw Accelerometer for Cadence

**What people do:** Use CMMotionManager.startAccelerometerUpdates() and try to detect footstrikes with peak detection algorithms on raw accelerometer data.
**Why it's wrong:** CMPedometer already does this with Apple's finely-tuned motion coprocessor algorithms. Raw accelerometer requires complex signal processing (noise filtering, axis fusion, peak detection) and will always be less accurate than Apple's built-in solution. It also drains more battery.
**Do this instead:** Use CMPedometer with `currentCadence`. Only fall back to raw accelerometer if CMPedometer cadence is unavailable on a specific device (check `isCadenceAvailable()`).

### Anti-Pattern 2: Frequent Song Switching

**What people do:** Switch the playing song every time cadence changes by even 1-2 BPM.
**Why it's wrong:** Runners' cadence fluctuates constantly. Switching songs every few seconds is a terrible user experience. Also, Spotify's queue/play API has rate limits.
**Do this instead:** Use a smoothing window (10-15 second rolling average) and a significant-change threshold (e.g., 5+ BPM shift sustained for 10+ seconds). Only switch when the runner has genuinely changed pace.

### Anti-Pattern 3: Relying Solely on Spotify Audio Features API

**What people do:** Assume they can call `GET /audio-features/{id}` to get BPM for any track.
**Why it's wrong:** This endpoint was deprecated November 2024 for new applications. New apps get 403 Forbidden.
**Do this instead:** Build a hybrid BPM data pipeline: community databases (GetSongBPM, MusicBrainz) + user-assisted tap-to-BPM + local caching. Accept that BPM data acquisition is a first-class architectural concern, not an API call.

### Anti-Pattern 4: Tight Coupling to Spotify SDK

**What people do:** Call SPTAppRemote methods directly from view models or UI code.
**Why it's wrong:** SPTAppRemote has complex lifecycle management (connect/disconnect on app state transitions, auth renewal). Spreading this across the codebase creates bugs. Also makes testing impossible without the Spotify app installed.
**Do this instead:** Wrap all Spotify interaction behind a `SpotifyAdapter` protocol. One class manages the SPTAppRemote lifecycle. Everything else talks to the protocol.

## Integration Points

### External Services

| Service | Integration Pattern | Notes |
|---------|---------------------|-------|
| Spotify App (iOS SDK) | SPTAppRemote for playback control, delegates for state changes | Requires Spotify app installed. Must disconnect on background, reconnect on foreground. Requires Spotify Premium. |
| Spotify Web API | REST via URLSession, OAuth2 bearer token | For search, user library, queue management. Separate auth token from App Remote. Rate limited. |
| Community BPM Database | REST API lookups, batch where possible | GetSongBPM.com or similar. Cache aggressively. May need API key. Verify accuracy. |
| Apple CoreMotion | CMPedometer for cadence, permission-gated | Requires "Motion & Fitness" permission. Check `isCadenceAvailable()`. Updates every ~2-3 seconds. |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| UI <-> Services | ViewModel pattern, @Observable classes | Views never touch adapters directly |
| Services <-> Adapters | Swift protocols, async/await | All adapter access through protocols |
| CadenceEngine <-> SongMatcher | AsyncStream of BPM values | Decoupled, SongMatcher subscribes to cadence stream |
| SongMatcher <-> BPMStore | Direct function calls (sync) | BPM lookups must be fast, all data local |
| PlaybackController <-> SpotifyAdapter | Async method calls | Queue track, play, pause, observe state |

## Build Order (Dependencies)

The following order respects component dependencies and delivers testable increments:

1. **Adapters first** -- CoreMotion adapter (cadence input) and Spotify adapter (playback output) are the two external interfaces. Build and test these in isolation. Everything else depends on them.

2. **BPM Store + data model** -- The cache layer that makes song matching possible. Must be populated before matching can work. Includes community BPM database integration.

3. **Cadence Engine** -- Wraps the CoreMotion adapter with smoothing logic. Depends on adapter protocol existing.

4. **Song Matcher** -- Pure logic that queries the BPM store. Depends on BPM store schema. Easily unit-testable.

5. **Playback Controller** -- Orchestrates the run session. Depends on Song Matcher (for what to play) and Spotify Adapter (for how to play). This is where the cadence-to-music loop lives.

6. **UI layer** -- Views and ViewModels. Depends on all services being defined (even if stubbed). Can be built in parallel with services using mock adapters.

7. **Background execution** -- The silent audio / audio session strategy. Built last because it's an enhancement to an already-working foreground experience. Requires integration testing on a real device.

**Key dependency chain:**
```
CoreMotion Adapter ─┐
                    ├─> Cadence Engine ─┐
BPM Store ──────────┤                   ├─> Playback Controller ─> UI
                    ├─> Song Matcher ───┘
Spotify Adapter ────┘
```

## Sources

- [Core Motion | Apple Developer Documentation](https://developer.apple.com/documentation/coremotion/)
- [CMPedometer | Apple Developer Documentation](https://developer.apple.com/documentation/coremotion/cmpedometer)
- [currentCadence | Apple Developer Documentation](https://developer.apple.com/documentation/coremotion/cmpedometerdata/currentcadence)
- [Spotify iOS SDK | Spotify for Developers](https://developer.spotify.com/documentation/ios)
- [SPTAppRemote Class Reference](https://spotify.github.io/ios-sdk/html/Classes/SPTAppRemote.html)
- [Spotify iOS SDK GitHub](https://github.com/spotify/ios-sdk)
- [Changes to Web API | Spotify for Developers](https://developer.spotify.com/blog/2024-11-27-changes-to-the-web-api)
- [Spotify Audio Features 403 Error (Community)](https://community.spotify.com/t5/Spotify-for-Developers/Web-API-Get-Track-s-Audio-Features-403-error/td-p/6654507)
- [Superpowered BPM Detection](https://superpowered.com/bpm-detection-key-detection-bar-detection-beat-detection-android-ios)
- [Perfect Cadence (reference app)](https://github.com/leafthelegend/Perfect-Cadence)
- [iOS Background Motion Updates (proof of concept)](https://github.com/robinmacharg/iOS-Background-Motion-updates)
- [Spotify Web API - Add to Queue](https://developer.spotify.com/documentation/web-api/reference/add-to-queue)

---
*Architecture research for: BeatStep -- iOS cadence-to-music sync running app*
*Researched: 2026-03-19*
