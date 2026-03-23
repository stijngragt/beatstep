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

## Cross-Milestone Trends

### Process Evolution

| Milestone | Sessions | Phases | Key Change |
|-----------|----------|--------|------------|
| v1.0 | ~8 | 5 | First milestone — established GSD workflow patterns |

### Cumulative Quality

| Milestone | Tests | Coverage | Zero-Dep Additions |
|-----------|-------|----------|-------------------|
| v1.0 | 28+ | Services layer | 0 (all deps justified) |

### Top Lessons (Verified Across Milestones)

1. Risk-first phase ordering catches blockers early
2. TDD for pure business logic pays off in engine/service layers
3. Device verification checkpoints catch real integration issues that unit tests miss
