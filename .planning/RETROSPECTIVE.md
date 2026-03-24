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

## Cross-Milestone Trends

### Process Evolution

| Milestone | Sessions | Phases | Key Change |
|-----------|----------|--------|------------|
| v1.0 | ~8 | 5 | First milestone — established GSD workflow patterns |
| v1.1 | ~3 | 4 | Parallel execution, faster phases, approval gates |

### Cumulative Quality

| Milestone | Tests | Coverage | Zero-Dep Additions |
|-----------|-------|----------|-------------------|
| v1.0 | 28+ | Services layer | 0 (all deps justified) |
| v1.1 | 35+ | Services + design tokens | 0 (zero new deps) |

### Top Lessons (Verified Across Milestones)

1. Risk-first phase ordering catches blockers early (v1.0, v1.1)
2. TDD for pure business logic pays off in engine/service layers (v1.0, v1.1)
3. Device verification checkpoints catch real integration issues that unit tests miss (v1.0, v1.1)
4. Tight phase scoping enables fast execution — sub-10min phases are achievable (v1.1)
5. Update docs when decisions are locked, not at audit time (v1.1 lesson from stale "electric green")
