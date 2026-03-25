# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

## Milestone: v1.0 — MVP

**Shipped:** 2026-03-23
**Phases:** 5 | **Plans:** 11 | **Sessions:** ~8

### What Was Built
- Spotify OAuth (PKCE) + background playback with lock screen controls
- BPM data pipeline: GetSongBPM API → Cloudflare Worker proxy → SwiftData cache
- Real-time cadence detection via CMPedometer with rolling average smoothing
- Core free run loop: cadence-to-BPM matching with half/double support, tolerance control
- Guided run mode: target BPM presets, warm-up/cool-down ramp state machine
- Smart song selection: danceability-ranked matching replaces random picks

### What Worked
- **Risk-first phase ordering** — tackling BPM pipeline (Phase 2) before cadence detection (Phase 3) caught the Spotify Audio Features deprecation early, leaving time for the Cloudflare Worker proxy solution
- **TDD for engine logic** — Phases 4 and 5 used RED/GREEN/REFACTOR, caught edge cases in matching and ramp logic before UI wiring
- **Device verification checkpoints** — Phases 3, 4, 5 included on-device human verification tasks that caught real integration issues (audio session, background playback)
- **Gap closure plans** — Phase 2 Plan 03 emerged organically when GetSongBPM was blocked by bot protection; the gap-closure pattern worked cleanly

### What Was Inefficient
- **SPTAppRemote → Web API migration** — Phase 1 built with SPTAppRemote, Phase 2 had to replace it with Web API player when PKCE was needed. Could have researched auth requirements earlier
- **Summary one-liner fields** — Not populated in SUMMARY.md files, making automated accomplishment extraction return nulls
- **Phase 5 ROADMAP checkboxes** — Plans showed as unchecked despite summaries existing; state tracking got slightly out of sync

### Patterns Established
- `RunEngineService` as central orchestrator pattern — all run logic flows through one service
- Cloudflare Worker proxy pattern for APIs with bot protection
- `@ObservationIgnored` on private stored properties to prevent @Observable macro conflicts
- `loadForTesting`/`setXForTesting` helpers for unit testing @Observable services
- Singleton services with `setContainer` pattern for SwiftData access outside views

### Key Lessons
1. **Check API deprecation status during research, not during implementation** — Spotify Audio Features deprecation was a known fact but only hit us mid-Phase 2
2. **Cloudflare Worker proxy is a reliable pattern** for APIs that block iOS URLSession — low latency, low cost, simple to deploy
3. **CMPedometer is far more reliable than raw accelerometer** for cadence — the research was right to recommend it over custom signal processing
4. **Smart selection needs fallback data** — danceability coverage from GetSongBPM is incomplete; defaulting to 50 prevents nil crashes but reduces selection quality for niche tracks

### Cost Observations
- Model mix: ~70% opus (execution), ~20% sonnet (verification/checking), ~10% haiku
- Sessions: ~8 across 5 days
- Notable: TDD plans (04-01, 05-01) completed faster than UI wiring plans due to fewer device checkpoints

---

## Milestone: v1.1 — Dark by Design

**Shipped:** 2026-03-24
**Phases:** 4 | **Plans:** 7 | **Sessions:** ~3

### What Was Built
- Complete design token system (color, typography, spacing, radii, component sizing) with #FF4545 heartbeat red accent
- Global dark mode enforcement via Info.plist + window-level override
- Tab navigation shell (Library/Run/Settings) with per-tab NavigationStack and global MiniPlayer
- All 8 view files migrated from hardcoded colors to design tokens
- Run tab landing screen with last-used playlist persistence
- Track count bug fix (nil=unknown hides count, 0=empty shows "0 tracks")
- App icon (ECG pulse mark via Core Graphics test-as-generator) and BEATSTEP wordmark

### What Worked
- **Parallel plan execution** — Wave 1 of Phase 9 ran both plans simultaneously, completing in half the time
- **Test-as-generator pattern** — Using a unit test to programmatically generate the app icon PNG was clever: reproducible, no external tools, validates dimensions automatically
- **User approval gates** — DS-05 checkpoint (design token review) and BRAND visual checkpoint both caught the right moment for human judgment
- **Lean phases** — 4 phases with 7 plans total, each phase tightly scoped. Phase 8 completed in 7 minutes across 2 plans

### What Was Inefficient
- **SUMMARY one-liner fields still not populated** — Same issue as v1.0; automated accomplishment extraction returns nulls
- **REQUIREMENTS.md stale wording** — "Electric green" was never updated to #FF4545 after the research phase locked the color decision. Caught during audit but should have been updated when the decision was made
- **Nyquist validation files created but never executed** — All 4 phases have draft VALIDATION.md but none went through the validation flow
- **Phase 8 VERIFICATION body/frontmatter mismatch** — Body says gaps_found, frontmatter says passed (gap was resolved but body text wasn't updated)

### Patterns Established
- Belt-and-suspenders dark mode (Info.plist + window override) for complete iOS coverage
- DesignTokens.swift as single source of truth for all visual constants
- Per-tab NavigationStack with global MiniPlayer via safeAreaInset on TabView
- Test-as-generator for programmatic asset creation (reproducible, no external tools)
- Enum with static computed properties for lightweight UserDefaults persistence

### Key Lessons
1. **Update requirements docs when design decisions are locked** — don't wait for the audit to catch stale wording
2. **Parallel execution pays off for independent plans** — Phase 9 wave 1 ran 2 agents simultaneously with no conflicts
3. **Small, focused phases execute fast** — v1.1 averaged 9 minutes per phase (vs v1.0's longer phases), proving tight scoping works
4. **Asset Catalog + pbxproj integration is the hardest part of iOS asset work** — the icon generation was simple but wiring PBXResourcesBuildPhase required careful surgery

### Cost Observations
- Model mix: ~60% opus (execution), ~30% sonnet (verification/integration), ~10% haiku
- Sessions: ~3 across 2 days
- Notable: Phase 8 (2 plans, 9 files modified) completed in 7 minutes total — fastest phase yet

---

## Milestone: v1.2 — The Right Flow

**Shipped:** 2026-03-24
**Phases:** 3 | **Plans:** 6 | **Sessions:** ~2

### What Was Built
- Zone-based running (Z1-Z5 + Free) with configurable BPM per zone in Settings, replacing effort labels
- Library playlists show analyzed/unanalyzed state with inline swipe-to-analyze action
- Value-framed 3-screen onboarding flow (Spotify, Health/Motion, Zones) gated at app root via AppState enum
- Settings permission recovery section for users who denied during onboarding
- Full-width pinned Run CTA on Run tab and ±BPM tolerance segmented picker
- HealthKit framework optional link for Apple Health read permissions

### What Worked
- **Features-before-gate sequencing** — Building zones (Phase 10-11) before onboarding (Phase 12) meant the onboarding gate was added after all gated features were verified working. Zero rework needed.
- **Thin UI wrapper approach** — Zones didn't touch RunEngineService at all. Mapping zone → runMode + targetBPM kept the change surface minimal.
- **AppState enum with static resolve()** — Testable routing logic outside SwiftUI, caught onboarding precedence issues in unit tests before they hit the UI.
- **Human checkpoint for onboarding** — Plan 12-02 checkpoint caught the right moment to verify the full 3-screen flow on device before marking complete.

### What Was Inefficient
- **SUMMARY one-liner fields still not populated** — Third milestone in a row; automated accomplishment extraction returns nulls. Should fix the executor template or stop expecting these.
- **Nyquist VALIDATION.md files remain draft** — All 3 phases created validation strategies but `nyquist_compliant` never set to true. Pattern from v1.1 repeated.
- **ScrollPosition → ScrollViewReader deviation** — Research recommended ScrollPosition (iOS 18+) but app targets iOS 17. The executor auto-fixed this, but research should check deployment target before recommending APIs.

### Patterns Established
- `AppState` enum at ContentView root for multi-state routing (onboarding → login → authenticated)
- `@AppStorage` flag tracking for permissions that iOS can't distinguish (HealthKit read .notDetermined)
- Forward-only ScrollView via `scrollDisabled(true)` + ScrollViewReader for onboarding-style flows
- Per-row scan progress tracking via `scanningPlaylistID` for inline feedback

### Key Lessons
1. **Check deployment target during research** — API recommendations should match the app's actual iOS version target, not the latest SDK
2. **Thin wrapper over existing services beats new services** — Zones are pure UI mapping to RunEngine's existing parameters. Resist the urge to build new infrastructure.
3. **HealthKit read permissions are asymmetric** — `.authorizationStatus()` always returns `.notDetermined` for read types. Must use custom flags for UI display.
4. **Onboarding gate placement matters** — Gate must evaluate BEFORE auth check to prevent tab bar flash. AppState enum precedence solved this cleanly.

### Cost Observations
- Model mix: ~60% opus (execution), ~30% sonnet (verification/integration), ~10% haiku
- Sessions: ~2 in a single day
- Notable: Entire milestone (3 phases, 6 plans) completed in a single day — fastest milestone yet at ~3 hours wall time

---

## Milestone: v1.3 — In The Zone

**Shipped:** 2026-03-25
**Phases:** 5 | **Plans:** 8 | **Sessions:** ~3

### What Was Built
- Reactive sync quality engine: SyncQuality/TempoMode models with cadenceDelta → syncQuality → color token reactive chain
- Color-coded cadence display with signed delta indicator, zone band visualization, ramp phase progress
- Subtle sync-state background color shift as subconscious feedback
- Integrated run player: 80pt album art, track info, BPM, 56pt+ playback controls
- Full-screen ActiveRunView via fullScreenCover with three-zone composition
- Long-press stop button with 2-second timer-based progress ring
- Tempo mode toggle (1:1/1:2) with reactive chain and UserDefaults persistence

### What Worked
- **Component-first architecture** — Building standalone previewable components (Phases 14-15) before assembling them (Phase 16) meant each component was verified independently. Assembly was just wiring, not debugging.
- **Static functions for testability** — LongPressStopButton.progress(), ZoneBandView.position(), RampPhaseIndicator.progress() all use the same pattern: pure static function → TDD → view calls function. Clean separation.
- **Direct @Observable reads** — ActiveRunView reads RunEngineService directly instead of passing @State copies. No stale data, no binding plumbing, fewer re-render bugs.
- **Gap closure workflow** — Audit caught PLR-04 missing UI toggle. Phase 17 added the one button needed. Clean cycle: audit → gap plan → execute → re-audit → pass.

### What Was Inefficient
- **SUMMARY one-liner fields still not populated** — Fourth milestone in a row. Should accept this won't be fixed and stop checking.
- **Nyquist VALIDATION.md files remain draft** — All 5 phases have draft validation strategies but none completed. Persistent pattern across all milestones.
- **PLR-04 gap** — Phase 13 claimed PLR-04 complete based on engine backend alone, but the requirement says "user can toggle." Should verify user-facing requirements against actual UI, not just API presence.
- **RunView.activeView hardcoded defaults** — Lines 138-143 use .inSync defaults during ~0.3s fullScreenCover animation. Documented and accepted as cosmetic, but could have been wired to live data for correctness.

### Patterns Established
- fullScreenCover with interactiveDismissDisabled for focused full-screen experiences
- MiniPlayer hidden via service state check (isRunActive) in ContentView
- Timer-based long-press with DragGesture.onEnded for reliable cancel detection
- Cool Down button pattern (full-width capsule, design tokens) reused for tempo toggle
- Three-zone VStack layout for run screens (status bar, hero content, controls)

### Key Lessons
1. **Verify user-facing requirements against UI, not just API** — PLR-04 "user can toggle" requires a visible control, not just a mutable property on a service
2. **Component-first → assembly is the right sequencing** — Build and verify each piece standalone, then compose. Assembly phase is fast and confident.
3. **Static pure functions are the best testability pattern in SwiftUI** — Extract computation into `static func`, test it, call from view. No view testing frameworks needed.
4. **Gap closure is a clean, fast cycle** — Audit → plan → execute → re-audit took one small phase. Don't fear gaps; just close them.

### Cost Observations
- Model mix: ~60% opus (execution), ~30% sonnet (verification/integration), ~10% haiku
- Sessions: ~3 across 2 days
- Notable: Phase 17 gap closure (1 plan, 1 file change) completed in ~12 minutes including human verification

---

## Milestone: v1.4 — Under The Hood

**Shipped:** 2026-03-25
**Phases:** 6 | **Plans:** 11 | **Sessions:** ~2

### What Was Built
- BPM confidence tracking: every cached BPM carries origin (API/manual) and confidence level with separate write paths
- Confidence badges: color-coded capsules (green/yellow/blue) in playlist view showing BPM reliability
- Tap BPM input: half-sheet tap-along interface with rolling 8-interval average, outlier rejection, haptic feedback
- Zero-BPM fallback: configurable behavior (skip/play regardless/prompt) in Settings, respected by run engine
- Sensor Lab: hidden debug screen with live accelerometer data, cadence readout, real-time waveform chart, configurable detection interval
- Step count fix (gap closure): wired live pedometer data into Sensor Lab via CadenceService

### What Worked
- **Pure-logic engine pattern** — TapBPMEngine as a standalone class (no UI dependency) enabled 11 unit tests covering all edge cases. Same pattern as v1.0's RunEngine approach.
- **Gap closure cycle speed** — Phase 23 (stepCount fix) went from audit finding → research → plan → execute → verify in a single session. The gap-closure workflow is now a well-oiled machine.
- **Separate write paths** — cacheFromAPI/cacheManual design prevented the most likely bug (API overwriting manual BPM) by making it structurally impossible. Correct by construction.
- **Lazy backfill over migration** — CachedBPM computed getter handles old records without a SwiftData migration. Zero risk of data loss on upgrade.
- **Integration checker** — Caught the stepCount gap (declared but never written) that phase-level verification missed. The cross-phase perspective is valuable.

### What Was Inefficient
- **SUMMARY one-liner fields still not populated** — Fifth milestone in a row. Officially accepting this as a known limitation.
- **Nyquist VALIDATION.md files remain draft** — All 6 phases created but none completed. Persistent across all 5 milestones.
- **stepCount gap should have been caught during planning** — The plan specified `stepCount` as a property but never included a task to write to it. Plan checker should verify that displayed properties have write paths.
- **Phase 22 VERIFICATION human_needed for items already verified** — User approved items 1, 3, 4 during the checkpoint but verifier still flagged them.

### Patterns Established
- Badge-as-button pattern: wrapping BPM capsule in Button for tap-to-action without conflicting with row tap
- Median-deviation outlier rejection for rhythm input (40% threshold + boundary guards)
- Hidden feature toggle: @AppStorage + tap-count gesture for developer features
- Swift Charts + drawingGroup() for real-time data visualization
- Service property exposure for cross-service data (CadenceService.stepCount for SensorLabView)

### Key Lessons
1. **Plan checkers should verify that displayed properties have write paths** — stepCount was declared and bound to UI but never assigned. Static analysis of data flow during planning would have caught this.
2. **Cross-phase integration checking is worth the cost** — The integration checker found a real bug that per-phase verification missed. Always run it at milestone audit.
3. **Lazy backfill beats migration for optional new fields** — Computed getters with nil-checks are simpler, safer, and reversible. Use this pattern for all backward-compatible model extensions.
4. **One gap closure phase is better than reopening a completed phase** — Phase 23 was clean, focused, and fast. Don't try to amend completed phases; add a new one.

### Cost Observations
- Model mix: ~60% opus (execution), ~30% sonnet (verification/integration), ~10% haiku
- Sessions: ~2 in a single day
- Notable: Entire milestone (6 phases, 11 plans, 55 commits) completed in a single day

---

## Milestone: v1.5 — One Way In

**Shipped:** 2026-03-25
**Phases:** 3 | **Plans:** 3 | **Sessions:** ~1

### What Was Built
- Run tab Start Run button fully wired with engine integration, playlist fetch, and fullScreenCover
- Old RunView.swift deleted — single run entry point enforced across entire codebase
- Library "Run with this playlist" CTA that writes LastRunPlaylist and switches tab via SelectedTabKey EnvironmentKey
- 4-page onboarding flow with playlist picker and inline BPM analysis before completion
- Returning user quick-start: last-used playlist, zone, and tolerance pre-loaded on Run tab appear

### What Worked
- **Smallest milestone yet** — 3 phases, 3 plans, 1 day. Tight scope with clear "kill the old, wire the new" objective executed cleanly.
- **EnvironmentKey for cross-tab navigation** — SelectedTabKey injection on the Library NavigationStack allowed PlaylistDetailView to switch tabs without deep binding chains. Clean, idiomatic SwiftUI.
- **Immediate fullScreenCover on tap** — Spotify app bounce during playback handoff causes missed .onChange callbacks. Setting showActiveRun = true immediately on tap was the right fix.
- **Delete-first approach** — Phase 25 deleted RunView.swift before adding alternatives. This "close the old path" approach prevents regression better than "add new path, then delete old."
- **Integration checker caught zero issues** — All 6 requirements wired correctly across phases. Clean integration for the first time.

### What Was Inefficient
- **Research disabled** — All 3 phases skipped research. This was appropriate for the scope (mostly wiring and deleting) but meant no VALIDATION.md files were generated.
- **Nyquist VALIDATION.md still missing** — Sixth milestone in a row. At this point it's a systemic gap in the workflow config, not a per-milestone issue.
- **Xcode CLI tools not configured** — Phase 26 executor couldn't run build verification. The code compiles (verified in later phases) but automated build checking during execution would catch issues earlier.
- **SUMMARY one-liner fields still null** — Sixth milestone. This is a permanent gap unless the summary template is changed.

### Patterns Established
- EnvironmentKey for cross-tab programmatic navigation (Library → Run tab)
- Three-state onboarding view pattern: loading → picker → analyzing (with progress)
- "No skip button" for critical onboarding steps that ensure data readiness

### Key Lessons
1. **Delete the old path before wiring the new** — removing RunView.swift first made it structurally impossible to regress. Grep-for-zero-references is the strongest verification.
2. **EnvironmentKey beats deep binding chains** — for cross-tab navigation, injecting at the NavigationStack level and reading via @Environment is cleaner than threading Bindings through 3+ layers.
3. **Immediate UI response over state-driven transitions** — when external systems (Spotify) can bounce or delay, don't gate UI transitions on their callbacks. Set the flag immediately, let the system catch up.
4. **Small milestones ship fast and clean** — 3 plans, zero gaps, zero rework. Scope discipline pays dividends.

### Cost Observations
- Model mix: ~60% opus (execution), ~30% sonnet (verification/integration), ~10% haiku
- Sessions: ~1 in a single day
- Notable: Entire milestone completed in under 1 hour wall time — fastest milestone yet

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Sessions | Phases | Key Change |
|-----------|----------|--------|------------|
| v1.0 | ~8 | 5 | First milestone — established GSD workflow patterns |
| v1.1 | ~3 | 4 | Parallel execution, faster phases, approval gates |
| v1.2 | ~2 | 3 | Single-day milestone, features-before-gate sequencing |
| v1.3 | ~3 | 5 | Component-first assembly, gap closure cycle, reactive chain |
| v1.4 | ~2 | 6 | Pure-logic engine pattern, integration checker value, lazy backfill |
| v1.5 | ~1 | 3 | Smallest milestone, delete-first approach, EnvironmentKey navigation |

### Cumulative Quality

| Milestone | Tests | Coverage | Zero-Dep Additions |
|-----------|-------|----------|-------------------|
| v1.0 | 28+ | Services layer | 0 (all deps justified) |
| v1.1 | 35+ | Services + design tokens | 0 (zero new deps) |
| v1.2 | 50+ | Services + models + onboarding | 0 (HealthKit is first-party) |
| v1.3 | 70+ | Services + models + views + run screen | 0 (all SwiftUI native) |
| v1.4 | 90+ | Services + models + views + engine + debug | 0 (Swift Charts is first-party) |
| v1.5 | 90+ | Services + models + views + onboarding + navigation | 0 (no new deps) |

### Top Lessons (Verified Across Milestones)

1. Risk-first phase ordering catches blockers early (v1.0, v1.1, v1.2)
2. TDD for pure business logic pays off in engine/service layers (v1.0, v1.1)
3. Device verification checkpoints catch real integration issues that unit tests miss (v1.0, v1.1, v1.2)
4. Tight phase scoping enables fast execution — sub-10min phases are achievable (v1.1, v1.2)
5. Update docs when decisions are locked, not at audit time (v1.1, v1.2)
6. Thin UI wrappers over existing services beat new infrastructure (v1.2 — zones needed zero RunEngine changes)
7. Check deployment target during research, not during execution (v1.2 — ScrollPosition/iOS 17 mismatch)
8. Component-first → assembly sequencing makes composition phases fast and confident (v1.3 — Phase 16 was pure wiring)
9. Verify user-facing requirements against actual UI, not just backend APIs (v1.3 — PLR-04 gap)
10. Static pure functions are the best SwiftUI testability pattern — extract, test, call (v1.3 — 3 components used this)
11. Cross-phase integration checking catches bugs per-phase verification misses (v1.4 — stepCount gap)
12. Plan checkers should verify displayed properties have write paths (v1.4 — stepCount declared but never assigned)
13. Lazy backfill via computed getters beats migration for backward-compatible model extensions (v1.4 — BPMConfidence)
14. Delete the old path before wiring the new — structural enforcement via grep-for-zero-references (v1.5 — RunView deletion)
15. EnvironmentKey beats deep binding chains for cross-tab navigation (v1.5 — SelectedTabKey)
16. Small, tightly-scoped milestones ship fast and clean — zero gaps, zero rework (v1.2, v1.5)
