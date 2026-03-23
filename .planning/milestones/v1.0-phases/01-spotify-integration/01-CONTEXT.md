# Phase 1: Spotify Integration - Context

**Gathered:** 2026-03-19
**Status:** Ready for planning

<domain>
## Phase Boundary

Authenticate with Spotify and control music playback from BeatStep, including in background. User can sign in, browse playlists, start playback, and use lock screen controls. BeatStep is a "turn it on and go" running companion -- not a music browsing app. The library is a playlist picker for selecting a song pool before a run.

</domain>

<decisions>
## Implementation Decisions

### Auth & session flow
- Spotify login is an onboarding gate -- can't proceed without it
- Premium required -- check on login, block free accounts with clear message
- Silent token refresh in background; only re-show login if refresh fails (e.g., user revoked access)
- Disconnect/logout option available in a settings screen

### Playback controls
- Minimal controls: play/pause and skip only (no seek, volume, or back)
- Persistent mini-player bar at bottom of screen showing track name, artist, and BPM
- No full now-playing screen -- mini-player is sufficient for Phase 1
- User can start playback by tapping a track in a playlist (connects library browsing to playback)

### Library browsing (playlist picker)
- Show playlists only -- no saved tracks, albums, or recently played
- This is a song pool selector, not a music browser -- user picks a playlist before their run, BeatStep handles the rest
- Playlists displayed as vertical list with cover art, name, and track count
- Tapping a playlist shows its track list; tapping a track starts playback from that point
- Paginated loading for large playlists (100+ tracks)
- No search or filtering in Phase 1

### Background behavior
- Music playback continues when app is backgrounded or phone is locked
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

</decisions>

<specifics>
## Specific Ideas

- BeatStep is a "turn it on and go" app -- you don't use it mid-run and you don't use it besides when you're running
- The app runs on top of Spotify -- it controls what's playing so the right song matches your cadence
- Pre-run flow: pick a playlist as your song pool -> start run -> BeatStep handles playback from that pool
- Mini-player shows BPM instead of album art -- more functional for the running context

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- None -- greenfield project, no existing codebase

### Established Patterns
- None yet -- Phase 1 will establish the foundational patterns (Swift/SwiftUI, project structure, Spotify SDK integration)

### Integration Points
- SPTAppRemote SDK for Spotify playback control and authentication
- Spotify Web API for library/playlist data
- MPRemoteCommandCenter for lock screen controls
- AVAudioSession for audio focus management

</code_context>

<deferred>
## Deferred Ideas

None -- discussion stayed within phase scope

</deferred>

---

*Phase: 01-spotify-integration*
*Context gathered: 2026-03-19*
