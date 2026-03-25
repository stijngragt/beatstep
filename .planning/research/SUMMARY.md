# Project Research Summary

**Project:** BeatStep v1.4 "Under The Hood"
**Domain:** iOS running music app -- debug tooling, manual BPM input, confidence tracking, zero-BPM fallback
**Researched:** 2026-03-25
**Confidence:** HIGH

## Executive Summary

BeatStep v1.4 is an infrastructure milestone that makes the BPM matching engine observable, correctable, and resilient. The work centers on four capabilities: a Sensor Lab debug screen for inspecting cadence detection internals, tap-to-BPM manual input for tracks the API misses, confidence indicators that show users where each BPM value came from, and configurable fallback behavior for tracks without BPM data. All four capabilities build on existing iOS frameworks (CoreMotion, SwiftUI Charts, SwiftData) with zero new external dependencies.

The recommended approach is model-first: extend the `CachedBPM` SwiftData model with optional `confidence` and `source` fields before building any UI. This schema change is the foundation that every other feature reads or writes. The migration must use optional String fields (not enums) to trigger SwiftData's automatic lightweight migration and preserve existing user data. After the model layer, confidence badges, tap BPM input, zero-BPM fallback, and Sensor Lab can proceed in dependency order with minimal risk.

The primary risks are data integrity problems: schema migration destroying existing BPM caches on upgrade, tap BPM silently overwriting API-verified values, and debug detection intervals leaking into production runs. All three are preventable through architectural separation (distinct write paths for API vs manual BPM, isolated SensorLabService for debug data) and upgrade testing (v1.3-to-v1.4 migration verification). A secondary risk is the zero-BPM skip fallback creating rapid-fire Spotify API calls when most tracks lack BPM data -- this requires a circuit breaker in the matching engine.

## Key Findings

### Recommended Stack

v1.4 requires zero new dependencies. Every capability maps to APIs already linked in the project or available in iOS 17.0.

**Core technologies:**
- **CMMotionManager** (raw accelerometer): Live sensor waveform in Sensor Lab -- independent from CMPedometer, must be lifecycle-managed to avoid battery drain
- **SwiftUI Charts (LineMark)**: Built-in waveform visualization for Sensor Lab, no third-party charting needed
- **SwiftData lightweight migration**: Adding optional `String?` fields to CachedBPM triggers automatic migration with zero boilerplate
- **UIImpactFeedbackGenerator**: One-line haptic confirmation for tap BPM input
- **Date arithmetic**: Tap BPM calculation from inter-tap intervals -- 15 lines of code, no audio analysis libraries

**What NOT to add:** AudioKit (50MB+ for timestamp math), Combine (codebase is @Observable-only), CoreHaptics (overkill for discrete taps), SwiftData VersionedSchema (not needed for optional fields).

### Expected Features

**Must have (table stakes):**
- BPM confidence indicator per track -- users need to distinguish API-verified from manual from unknown
- Configurable zero-BPM behavior -- "skip" (current silent default) vs "play regardless"
- Tap BPM input -- universal manual override for tracks the API misses (minimum 4 taps, 8 for stability, outlier rejection)
- Zero-BPM visibility -- show count of skipped tracks, not silent exclusion

**Should have (differentiators):**
- Sensor Lab debug screen -- no running music app exposes raw sensor data; builds algorithm trust
- Configurable detection interval -- transforms desk testing speed (0.5s vs 5.0s window)
- Pre-run BPM coverage summary -- "42/50 tracks matched" gives users agency before starting

**Defer (v1.4.x or v1.5+):**
- Live confidence badge in RunPlayerView -- nice but not blocking
- Batch tap BPM workflow -- only if demand materializes; most users have 5-10 unanalyzed tracks
- Sensor Lab accelerometer graph -- move to v1.5 if SwiftUI Charts performance is sufficient for basic data
- Auto-BPM via microphone -- fragile, battery-heavy, accuracy problems; tap BPM covers the need

### Architecture Approach

The architecture follows BeatStep's established pattern: @Observable services own state, SwiftUI views observe them, SwiftData persists structured data, UserDefaults handles preferences. v1.4 adds 5 new files (SensorLabView, TapBPMView, BPMConfidenceBadge, BPMConfidence enum, ZeroBPMFallback enum) and modifies 7 existing files. The critical architectural decision is keeping SensorLabService completely isolated from CadenceService -- they use different CoreMotion subsystems (CMMotionManager vs CMPedometer) and must not share configuration state.

**Major components:**
1. **CachedBPM + BPMConfidence** -- Extended model with confidence/source fields; enum provides type safety over String storage
2. **BPMCacheService** -- Gains separate write paths: `cacheFromAPI()` and `cacheManualBPM()` to prevent silent overwrites
3. **TapBPMView** -- Modal sheet with rolling 8-interval average, outlier rejection, stability indicator, explicit save
4. **ZeroBPMFallback** -- UserDefaults-backed enum read by RunEngineService during song selection; three modes (skip/playRegardless/prompt)
5. **SensorLabView + SensorLabService** -- Isolated debug screen behind Settings toggle; lifecycle-managed to prevent battery drain

### Critical Pitfalls

1. **Schema migration breaking existing BPM cache** -- Add fields as `String?` optionals only. Test upgrade path from v1.3 with populated data. Non-optional fields cause destructive migration and data loss.
2. **Debug detection interval leaking into production** -- SensorLabService must be completely isolated from CadenceService. Debug interval lives in SensorLabService only, never persisted to shared UserDefaults.
3. **Tap BPM silently overwriting API values** -- Separate write paths (`cacheFromAPI` vs `cacheManualBPM`). Show existing API value in tap UI. Require explicit "Override" confirmation. Store both values so original is never lost.
4. **Zero-BPM skip loop causing Spotify rate limits** -- Circuit breaker after 3 consecutive no-match cycles. Auto-switch to "play regardless" with toast notification. Pre-run coverage warning when BPM coverage is below 50%.
5. **Confidence badge colors clashing with sync state colors** -- Use icons (checkmark/tilde/hand) instead of traffic-light colors. Reserve colored indicators for run-time sync state only.

## Implications for Roadmap

Based on research, suggested phase structure:

### Phase 1: BPM Confidence Model + Service Layer
**Rationale:** Every other feature depends on confidence/source data existing in the model. Schema migration must be the first thing built and verified.
**Delivers:** Extended CachedBPM model, BPMConfidence enum, separated write paths in BPMCacheService, LibraryScanService writing confidence during scans.
**Addresses:** BPM confidence indicator (foundation), source tracking for all downstream features.
**Avoids:** Schema migration crash (Pitfall 1), stale confidence after re-scan (Pitfall 5), tap BPM overwriting API values (Pitfall 3 -- prevention via write path separation).

### Phase 2: BPM Confidence Badges in UI
**Rationale:** With the model in place, badges are low-complexity visual work. Must exist before tap BPM so tapped values get immediate visual feedback.
**Delivers:** BPMConfidenceBadge view component, TrackRow integration in PlaylistDetailView.
**Addresses:** BPM confidence indicator per track (table stakes feature).
**Avoids:** Confidence/sync color clash (Pitfall 8 -- design decision here carries forward).

### Phase 3: Tap BPM Input
**Rationale:** Primary way users resolve zero-BPM tracks. Requires confidence model (Phase 1) for source tracking and badges (Phase 2) for display.
**Delivers:** TapBPMView modal, BPMCacheService manual write path, PlaylistDetailView integration.
**Addresses:** Tap BPM input (table stakes), manual BPM for unanalyzed tracks.
**Avoids:** Silent API overwrite (Pitfall 3), beat subdivision ambiguity (Pitfall 7 -- 2x/0.5x detection must ship with initial UI).

### Phase 4: Zero-BPM Fallback
**Rationale:** Completes the BPM data quality story. With tap BPM available (Phase 3), users have a path to fix tracks before falling back.
**Delivers:** ZeroBPMFallback enum, RunEngineService fallback policy, SettingsView picker, pre-run coverage summary.
**Addresses:** Configurable zero-BPM behavior (table stakes), pre-run coverage summary (differentiator).
**Avoids:** Rapid-fire Spotify API calls (Pitfall 4 -- circuit breaker must ship with fallback config).

### Phase 5: Sensor Lab
**Rationale:** Debug/developer tooling with no feature dependencies on Phases 1-4. Last because it serves development workflow, not end-user BPM quality.
**Delivers:** SensorLabService, SensorLabView, CadenceService debug extensions, Settings debug toggle, configurable detection interval.
**Addresses:** Sensor Lab debug screen (differentiator), configurable detection interval (differentiator).
**Avoids:** Battery drain from accelerometer (Pitfall 6), debug interval leaking to production (Pitfall 2).

### Phase Ordering Rationale

- **Model before UI:** SwiftData migration must land and be verified before any view reads the new fields. Getting this wrong destroys user data.
- **Badges before Tap BPM:** Tap BPM results need visual confirmation via confidence badges. Building badges first gives immediate feedback when manual values are saved.
- **Tap BPM before Fallback:** Users need a way to fix zero-BPM tracks before configuring fallback behavior. The features are more useful together in this order.
- **Sensor Lab last:** Fully independent of the BPM confidence/fallback work stream. Could theoretically be built in parallel with Phases 2-4 if capacity allows.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 3 (Tap BPM):** Beat subdivision ambiguity (half/double time detection), tap timing precision on main thread, UX for showing existing API value during override flow. Research the interaction between Spotify playback and tap timing.
- **Phase 4 (Zero-BPM Fallback):** Circuit breaker threshold tuning, prompt-mode coordination between RunEngineService and ActiveRunView without blocking. Test with real playlists at various coverage levels.

Phases with standard patterns (skip research-phase):
- **Phase 1 (Model):** SwiftData lightweight migration is well-documented. Pattern is add optional field, done.
- **Phase 2 (Badges):** Standard SwiftUI view component. Existing TrackRow pattern to follow.
- **Phase 5 (Sensor Lab):** CMMotionManager and SwiftUI Charts are well-documented. Lifecycle management is the only concern and the pattern is straightforward (onDisappear + scenePhase).

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Zero new dependencies. All APIs verified against iOS 17.0 target. Codebase inspection confirms integration points. |
| Features | HIGH | Clear dependency graph. Feature scope is well-bounded. Anti-features identified and excluded. |
| Architecture | HIGH | Extends established codebase patterns (@Observable, SwiftData, UserDefaults). No architectural paradigm shifts. |
| Pitfalls | HIGH | 8 specific pitfalls with prevention strategies; derived from codebase inspection + Apple docs. |

**Overall confidence:** HIGH

### Gaps to Address

- **Tap BPM timing precision:** Research suggests `Date()` on main thread may drift at high BPM (>160). May need `CADisplayLink` or `mach_absolute_time()`. Validate during Phase 3 implementation.
- **SwiftUI Charts performance at 50Hz:** If accelerometer waveform drops frames on older devices, fallback to Canvas drawing. Test during Phase 5 on iPhone 12 or equivalent.
- **Prompt fallback UX during active run:** The `.prompt` mode requires showing an alert during a run without blocking RunEngineService. The non-blocking pattern (published property + view observation) is designed but untested. Consider deferring `.prompt` to v1.4.x if skip + playRegardless cover the need.
- **Batch confidence fetch performance:** Individual SwiftData queries per track for confidence badges may be sluggish on 500+ track playlists. Plan a batch fetch approach during Phase 2 if performance testing shows issues.

## Sources

### Primary (HIGH confidence)
- [Apple CMMotionManager Documentation](https://developer.apple.com/documentation/coremotion/cmmotionmanager) -- singleton requirement, accelerometer API, update intervals
- [Apple Core Motion Documentation](https://developer.apple.com/documentation/coremotion/) -- CMPedometer vs CMMotionManager independence
- [SwiftData lightweight vs complex migrations](https://www.hackingwithswift.com/quick-start/swiftdata/lightweight-vs-complex-migrations) -- optional field = automatic migration
- Direct codebase analysis: CadenceService.swift, BPMCacheService.swift, CachedBPM.swift, RunEngineService.swift, PlaylistDetailView.swift, SettingsView.swift, LibraryScanService.swift

### Secondary (MEDIUM confidence)
- [Pro Tap Tempo: Accurate BPM Detection Tips](https://metronomeonline.org/blog/pro-tap-tempo-accurate-bpm-detection-tips) -- 8-tap window, outlier filtering, stabilization patterns
- [Apple Developer Forums -- SwiftData migration](https://developer.apple.com/forums/thread/738812) -- community confirmation of lightweight migration behavior
- [Building SwiftUI debugging utilities - Swift by Sundell](https://www.swiftbysundell.com/articles/building-swiftui-debugging-utilities/) -- debug screen patterns

### Tertiary (LOW confidence)
- [Garmin Forums: Cadence drops to zero](https://forums.garmin.com/sports-fitness/running-multisport/f/forerunner-965/370223/running-power-and-cadence-randomly-drop-to-zero-in-the-middle-of-a-run) -- real-world zero-cadence scenarios (user reports, not systematic data)

---
*Research completed: 2026-03-25*
*Ready for roadmap: yes*
