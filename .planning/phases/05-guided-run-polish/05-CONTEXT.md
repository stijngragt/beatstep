# Phase 5: Guided Run + Polish - Context

**Gathered:** 2026-03-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Add guided run mode where the runner sets a target BPM and music guides their pace. Includes warm-up/cool-down ramping, energy-based smart song selection (replacing pure random), and catalog discovery when the playlist pool runs low. This completes BeatStep's v1 feature set.

</domain>

<decisions>
## Implementation Decisions

### Guided run setup
- Segmented control on RunView idle state: "Free" / "Guided" — selecting Guided reveals target BPM configuration
- Target BPM set via named pace presets ("Easy Jog", "Steady", "Fast" etc.) with a "Custom" option that opens a numeric picker
- Tolerance picker (Tight/Normal/Loose) applies to both free run and guided run — same behavior
- Persist last-used mode (Free/Guided) and last target BPM to UserDefaults between runs (same pattern as tolerance persistence)

### Warm-up/cool-down ramp
- Always ramp in guided mode: ~3-5 min warm-up from ~140 BPM stepping up to target, ~3-5 min cool-down stepping back down
- Step-based progression: each new song is ~5-10 BPM closer to (or further from) target BPM — noticeable song-by-song progression
- Cool-down triggered manually via a "Cool Down" button (replaces or sits alongside "Stop Run" during guided runs)
- Visual feedback: subtle phase label only — "Warming up" / "At pace" / "Cooling down" on the run screen. No target BPM number shown.

### Genre/mood song selection (BPM-06)
- Implicit from playlist — no explicit mood/genre UI. The playlist is the preference.
- Among BPM matches, rank by energy + danceability data (higher energy during active running, lower during ramp phases)
- Energy/danceability data sourced from GetSongBPM API extras (already using this API via Cloudflare proxy). Research will confirm field availability.
- Smart selection applies to BOTH free run and guided run — replaces pure random selection from Phase 4

### Catalog discovery
- Auto-fallback: when playlist has fewer than ~3 songs matching the current target BPM, auto-discover from Spotify catalog via BPMDiscoveryService
- On-demand mid-run: discover as the pool runs low, not pre-run batch
- Discovered songs auto-saved to "BeatStep Discoveries" playlist via existing BPMDiscoveryService.saveToDiscoveryPlaylist()
- Applies to BOTH free run and guided run modes

### Claude's Discretion
- Named pace preset values and labels
- Exact warm-up/cool-down duration and step increments
- How to integrate guided mode into RunEngineService (extend existing vs. new service)
- Cool Down button placement and styling
- Discovery batch size and rate limiting strategy
- Fallback behavior if GetSongBPM doesn't provide energy data

</decisions>

<specifics>
## Specific Ideas

- This is the final phase — BeatStep ships after this. Both modes should feel polished and complete.
- "Warming up" / "At pace" / "Cooling down" labels should be subtle, not dominating — the run screen stays clean and focused on cadence
- Discovery should feel invisible — runner shouldn't notice when a discovered song plays vs. a playlist song
- Smart selection should make the music feel curated rather than random, even in free run mode

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `RunEngineService.shared`: Core orchestration engine (cadence monitoring, BPM matching, song-end detection, no-repeat pool). Needs guided mode extension.
- `BPMDiscoveryService.shared`: `discoverTracks(atBPM:)` finds Spotify catalog tracks at target BPM via GetSongBPM + Spotify search. `saveToDiscoveryPlaylist()` creates/updates "BeatStep Discoveries" playlist. Built in Phase 2, unused until now.
- `BPMTolerance`: Enum with Tight(±3)/Normal(±7)/Loose(±12) presets and UserDefaults persistence. Reusable for guided mode.
- `TolerancePicker`: SwiftUI segmented control, reusable pattern for mode picker
- `GetSongBPMService.shared`: Cloudflare Worker proxy for BPM lookups — may also return energy/mood data
- `CadenceService.shared`: Live SPM + trend + state (idle/detecting/active/paused)

### Established Patterns
- Singleton services with `.shared` pattern
- `@Observable` for reactive SwiftUI state
- `@ObservationIgnored` on private stored properties to avoid macro conflicts
- UserDefaults for persisting user preferences (tolerance, will extend to mode + target BPM)
- `play(uri:)` without contextURI for deterministic playback

### Integration Points
- `RunView`: Add Free/Guided segmented control to idle state, target BPM picker for guided, "Cool Down" button during guided run, ramp phase labels during active state
- `RunEngineService`: Add guided mode logic (fixed target BPM, ramp phases, smart selection ranking, catalog discovery fallback)
- `BPMDiscoveryService`: Wire into RunEngineService for on-demand discovery when pool runs low
- `GetSongBPMService`: Investigate energy/danceability fields in API response for smart ranking

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 05-guided-run-polish*
*Context gathered: 2026-03-23*
