# Feature Research

**Domain:** iOS running/music app — onboarding, playlist state UX, zone-based running
**Researched:** 2026-03-24
**Confidence:** MEDIUM-HIGH

## Scope Note

This file covers NEW features for v1.2 "The Right Flow" only. All v1.0/v1.1 features (cadence detection, BPM matching, Spotify playback, free/guided run, design system, tab nav) are shipped and stable. Research below addresses: onboarding flow, playlist analyzed state UX, zone-based running, inline analyze action, full-width Run CTA, and BPM tolerance picker redesign.

---

## Feature Landscape

### Table Stakes (Users Expect These)

Features users assume exist in a polished iOS fitness app. Missing these = product feels unfinished or untrustworthy.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Value-framed permission screens | iOS users have learned to deny permissions reflexively. A pre-prompt screen explaining "why we need this" before showing the system dialog is the industry standard. Apps that go straight to the system dialog get higher denial rates. Headspace, Strava, Nike Run Club all use pre-prompts. | LOW | Show a branded screen with benefit copy before `requestAuthorization`. One screen per permission type (Spotify, HealthKit). Use the permission-priming pattern: tell the user what they'll gain, then trigger the system dialog. |
| Re-triggerable permissions from Settings | Users who denied a permission at first launch need a recovery path. Without it, they hit a dead end — the app is broken for them with no obvious fix. | LOW | Store onboarding completion state in `UserDefaults`. Settings tab shows a "Reconnect Spotify" row and "Enable Health Access" row when permissions are missing. Tapping deep-links to the iOS Settings app via `UIApplication.openSettingsURLString`. |
| Visible analyzed/unanalyzed state on playlists | Users need to know which playlists are ready to run with. If BPM data hasn't been fetched, running against that playlist will fail silently or produce poor results. State visibility is the table stake; the inline action is the differentiator. | MEDIUM | Playlist rows in Library need a visual indicator. Common patterns: a badge, icon, or muted label ("Not analyzed" vs a checkmark). The state comes from `BPMCacheService` — check whether cached BPM count for a playlist meets a threshold. |
| Prominent Run CTA | The primary action of the app is starting a run. Burying this behind a small button or requiring navigation through multiple screens violates "primary action = biggest button" convention. Nike Run Club, Runna, and Strava all use a full-width primary CTA for their core action. | LOW | Full-width button at bottom of Run tab. `Button` with `.frame(maxWidth: .infinity)` and `.buttonStyle(.borderedProminent)`. Keep consistent with the existing `#FF4545` accent. |
| Effort/zone labels users recognize | "Z1–Z5" and "Free" maps to training zone vocabulary users know from Garmin, Apple Watch, Strava, and coaching apps. Generic labels like "Easy/Medium/Hard" feel toy-like. Zone labels signal that the app understands running. | LOW | Replace current effort labels with Zone 1–5 + Free. Zone numbers are the recognized standard across platforms. Include brief descriptors (Recovery, Endurance, Tempo, Threshold, Max) as subtitles. |

### Differentiators (Competitive Advantage)

Features that set BeatStep apart or deepen the core value proposition.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Inline analyze action on playlist row | Competing apps (Spotify itself, Pacemaker) require navigating into a detail screen or finding a buried menu to trigger analysis. An inline action on the row — a button or swipe action — lets users analyze playlists from the list without a context switch. | MEDIUM | Two options: (a) trailing swipe action (`swipeActions`) on playlist row, or (b) a small analyze button rendered on the row alongside the state indicator. Option (b) is more discoverable; option (a) is more iOS-native. Recommendation: trailing swipe for cleanliness, with the state badge acting as a hint that an action exists. |
| Zone BPM defaults with user-configurable overrides | Apps like Runna show zones but don't let users adjust the BPM targets. Runners who know their actual cadence zones (from a lactate test or Garmin data) want to override defaults. This turns zone-based running from a rough guide into a personalized training tool. | MEDIUM | Store zone BPM values in a settings struct (backed by `UserDefaults` or a simple value model). Provide sensible defaults (see cadence table below). Expose editable fields per zone in Settings. Validate input: BPM must be in 100–220 range, each zone's upper must exceed its lower. |
| BPM tolerance as segmented control showing ±delta | Most running apps with BPM tolerance use a slider (imprecise on small screens) or a text field (requires keyboard). A segmented control with three pre-calibrated options — Tight (±3), Normal (±7), Loose (±12) — communicates exactly how many BPMs of wiggle room the user will get, in terms they can reason about. This is more understandable than a percentage. | LOW | Replace current tolerance control with `Picker` using `.pickerStyle(.segmented)`. Segments: "±3 BPM", "±7 BPM", "±12 BPM". Map to existing tolerance logic — the values are absolute BPM delta, which is what `BPMMatchingService` already uses (HIGH confidence based on codebase). |
| Onboarding with zone vocabulary introduction | Most onboarding flows are account setup. BeatStep's onboarding can explain the zone model in 1–2 screens, so the Run tab makes immediate sense on first use. Users who understand the zone model are more likely to use guided mode instead of defaulting to free run only. | LOW | One brief "How it works" screen after permissions showing the zone concept. Keep it 2–3 sentences max. Skippable — don't gate the app on reading it. |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Auto-analyze all playlists on first launch | "Just analyze everything automatically" | BPM lookups cost API calls against GetSongBPM (rate limited) and are slow for large libraries. Analyzing 50 playlists × 50 songs each = 2,500 API calls. This will hit rate limits, create a terrible first-launch experience, and exhaust the Cloudflare Worker proxy budget. | Analyze on demand. Show state clearly so users know which playlists need analysis. Let them choose what to analyze. |
| Full onboarding quiz (goals, fitness level, preferred genres) | "Personalization from day one" | Every additional question in onboarding reduces completion rate (studies show 20–40% drop per extra screen). BeatStep's value is immediate — music matching your cadence — not personalized recommendations based on a quiz. | Get users to their first run fast. Personalization surfaces naturally through zone selection and playlist choice. |
| Blocking permission gate | "Force users to grant Spotify access before using the app" | Blocking gates on permissions increase denial rates and App Store rejections (Apple guideline 5.1.1 — don't require unnecessary info before providing app value). | Show the value proposition first. Ask for permission second. Make the cost of denial visible but not coercive. |
| Zone-based heart rate monitoring | "Auto-detect which zone the user is in based on HR" | Requires HealthKit continuous HR reading during a run, real-time zone calculation, and dynamic BPM target adjustment mid-run. This is a substantial new system touching RunEngineService, CadenceService, and HealthKit integration. Out of scope for v1.2. | Users select their target zone before starting a run. Zone = cadence target. No HR required. |
| Granular per-song analyze status | "Show which individual songs are analyzed vs not" | Song-level state display requires a different list layout, adds complexity to the playlist detail screen, and creates noise. Users care about "is this playlist ready to run with?" not "which of these 47 songs has a cached BPM?" | Playlist-level analyzed state only. A playlist is "analyzed" when enough tracks have BPM data. |

---

## Feature Dependencies

```
Onboarding flow
    └── requires: Permission pre-prompt screens designed
    └── requires: UserDefaults flag for onboarding completion
    └── enables: Re-triggerable permissions from Settings (same permission screens reused)
    └── note: Onboarding shows BEFORE tab navigation loads on first launch

Zone-based running (Z1-5 + Free)
    └── requires: Zone BPM defaults defined (research-derived values below)
    └── requires: Zone model struct (name, BPM range, description)
    └── enables: Zone-configurable overrides in Settings (additional feature)
    └── note: Replaces effort label enum in RunView; RunEngineService BPM target logic unchanged

Zone BPM defaults (user-configurable)
    └── requires: Zone model defined
    └── requires: Settings UI for per-zone BPM editing
    └── note: Persisted in UserDefaults; falls back to compiled-in defaults if not set

Playlist analyzed state (Library view)
    └── requires: BPMCacheService query to count cached tracks per playlist
    └── enables: Inline analyze action (state indicator is the trigger context)
    └── note: "Analyzed" threshold: suggest ≥70% of tracks have cached BPM

Inline analyze action
    └── requires: Playlist analyzed state display (users need to see state to act on it)
    └── requires: Existing BPMAnalysisService / GetSongBPMService analyze flow
    └── note: Swipe action triggers the same analysis flow already used in PlaylistDetailView

Full-width Run CTA
    └── requires: Nothing (isolated UI change to RunView bottom area)
    └── note: Confirm Run tab state when no playlist is selected — show CTA disabled or with prompt

BPM tolerance segmented control
    └── requires: Nothing (replaces existing tolerance UI in SettingsView)
    └── note: Values ±3/±7/±12 map to existing BPM tolerance field in RunEngineService

Re-triggerable onboarding from Settings
    └── requires: Onboarding flow completed
    └── requires: Permission state detection (check if Spotify token exists, if HealthKit authorized)
    └── note: Settings rows open iOS Settings via UIApplication.openSettingsURLString for already-denied permissions
```

### Dependency Notes

- **Onboarding must show before the main tab view on first launch.** Pattern: `ContentView` checks `UserDefaults.bool(forKey: "onboardingComplete")`; if false, presents `OnboardingView` as a full-screen cover. After completion, sets the flag and dismisses. This avoids re-architecting the app for first-launch state.

- **Analyzed state requires a BPMCacheService query per playlist.** `BPMCacheService` stores BPM data per track ID. To compute playlist analyzed state, the app needs to query how many tracks in the playlist have cached BPM entries. This may require a new method on `BPMCacheService` — `cachedTrackCount(for playlistID:)` or similar. Adds a pass over SwiftData on playlist list load.

- **Inline analyze action reuses existing analysis logic.** `PlaylistDetailView` already triggers BPM analysis for a playlist's tracks. The inline action extracts that trigger into a reusable method on a ViewModel or the service layer, callable from both the row action and the detail screen.

- **Zone model is a new type, not a modification of existing types.** `RunEngineService` currently takes a BPM target value. Zone-based running maps a zone selection to a BPM value and passes it in — the engine itself does not need to know about zones.

---

## Cadence/BPM Zone Reference

Research-derived typical cadence ranges by running effort zone. These inform zone BPM defaults.

| Zone | Name | Typical Cadence (SPM) | Recommended Default BPM | Effort Character |
|------|------|----------------------|------------------------|-----------------|
| Z1 | Recovery | 150–164 | 155 | Walking-to-jog pace; fully conversational; breathing effortless |
| Z2 | Endurance | 160–170 | 165 | Easy jog; sustainable for long runs; can hold full sentences |
| Z3 | Tempo | 170–178 | 174 | Comfortably uncomfortable; limited to short phrases |
| Z4 | Threshold | 175–182 | 178 | Hard; breathing labored; single-word responses only |
| Z5 | Max | 180–190+ | 185 | All-out sprint; not sustainable; speech collapses |
| Free | Free | n/a | n/a | Matches detected cadence; no target BPM set |

Note: Cadence (steps per minute) maps 1:1 to music BPM for on-beat running. These defaults are starting points — configurable per user. Z1–Z2 overlap exists by design; stride length varies at the same cadence.

Confidence: MEDIUM. Derived from multiple sources. Individual runners vary ±15 SPM. User-configurable overrides are essential — defaults are just sensible starting points, not prescriptions.

---

## Permission Priming Pattern

The permission-priming pattern used by fitness apps (Headspace, Strava, Nike Run Club):

1. **Custom pre-prompt screen** — app's own screen explaining: "BeatStep needs access to your Spotify account to queue music" with a benefit statement and a CTA ("Continue").
2. **System permission dialog** — triggered only after user taps the CTA on the custom screen.
3. **Denial recovery** — if the user denies, show a non-blocking informational state (not an error) with a "Go to Settings" link.

For BeatStep v1.2, two permissions need priming:
- **Spotify OAuth** — already exists (LoginView). Needs value-framed redesign of the copy and layout.
- **Apple Health** — new for v1.2. Pre-prompt: "Optionally connect Health to log your runs." Make it skippable — Health integration is not core to the running experience.

Re-triggerable onboarding from Settings: Settings rows should show "Reconnect Spotify" and "Connect Apple Health" when permissions are missing or expired. Tapping opens iOS Settings for Health; for Spotify, re-triggers the OAuth flow.

---

## MVP Definition

### This Milestone (v1.2) — All Eight Features

These are all P1 for the milestone. Each is scoped and achievable without deep architectural change.

- [ ] Onboarding flow with value-framed Spotify + Apple Health permission screens
- [ ] Re-triggerable onboarding from Settings for missed permissions
- [ ] Library playlists show analyzed/unanalyzed state
- [ ] Analyze button inline with playlist row (swipe action)
- [ ] Zone-based running: Zone 1–5 + Free replacing effort labels
- [ ] Zone BPM defaults with user-configurable overrides in Settings
- [ ] Full-width Run CTA at bottom of Run tab
- [ ] BPM tolerance as segmented control showing ±3, ±7, ±12 BPM

### Add After Validation (v1.x)

- [ ] Zone auto-detection from Apple Health HR data — requires real-time HealthKit HR during run; high complexity, high value if users adopt Health integration
- [ ] Per-zone playlist pairing — suggest/remember which playlists work best at each zone

### Future Consideration (v2+)

- [ ] Workout summary with zones run — post-run screen showing time in each zone
- [ ] Shared zone configurations — export/import BPM zone settings

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Onboarding flow (Spotify pre-prompt) | HIGH — first impression; affects permission grant rate | LOW — new screens, no service changes | P1 |
| Re-triggerable permissions from Settings | HIGH — recovery path for denied permissions | LOW — Settings rows + openSettingsURLString | P1 |
| Playlist analyzed state display | HIGH — users can't make informed playlist choice without it | MEDIUM — BPMCacheService query per playlist | P1 |
| Inline analyze action | HIGH — removes navigation friction for the most common action | MEDIUM — extracts existing logic; swipeActions UI | P1 |
| Zone-based running (Z1–5 + Free) | HIGH — vocabulary users know; positions app as serious training tool | LOW — new enum, same RunEngine BPM target logic | P1 |
| Zone BPM overrides in Settings | MEDIUM — advanced users only; defaults serve most users | MEDIUM — settings UI + UserDefaults persistence | P1 |
| Full-width Run CTA | MEDIUM — discoverability; most users will find the current button | LOW — frame modifier on existing button | P1 |
| BPM tolerance segmented control | MEDIUM — clarity improvement; existing tolerance works | LOW — replace existing picker with segmented Picker | P1 |

**Priority key:**
- P1: Must have for this milestone
- P2: Should have, add when possible
- P3: Nice to have, future consideration

---

## Competitor Feature Analysis

| Feature | Strava | Nike Run Club | Runna | Pacemaker | BeatStep v1.2 Approach |
|---------|--------|---------------|-------|-----------|------------------------|
| Onboarding with permission priming | Yes — notifications pre-prompt | Yes — location pre-prompt with benefit copy | Yes — goal-setting flow + permissions | Minimal | Value-framed Spotify + skippable Health screens |
| Zone-based running | Z1–5 (HR-based) | Guided runs with effort labels | Full 5-zone + custom HR zones | Not applicable | Z1–5 cadence-based + Free; no HR required |
| Analyzed/ready state for content | N/A | N/A | Workout "ready" indicators | Playlist analyzed badge | Analyzed indicator on playlist row |
| Re-triggerable settings for permissions | Settings → Connected Apps | Settings → Privacy | Settings → Integrations | N/A | Settings tab rows with direct re-auth |
| Tolerance / matching settings | N/A | N/A | N/A | BPM match setting (slider) | Segmented control: ±3/±7/±12 BPM |

---

## Sources

- [Permission Priming Pattern — UserOnboard](https://www.useronboard.com/onboarding-ux-patterns/permission-priming/)
- [App Onboarding Best Practices for iOS Developers 2025 — Medium](https://ravi6997.medium.com/app-onboarding-best-practices-for-ios-developers-f65e29327a58)
- [Building a Better Onboarding Flow in SwiftUI for iOS 18+ — Rivera Labs](https://www.riveralabs.com/blog/swiftui-onboarding/)
- [Running BPM Mastery: 2025 Heart Rate and Cadence Playbook — BPM Finder](https://bpm-finder.net/posts/running-bpm)
- [How to Use Heart Rate Zones to Improve Your Running — Strava](https://stories.strava.com/articles/how-to-use-heart-rate-zones-to-improve-your-running)
- [Finding Your Optimal Running Cadence — TrainingPeaks](https://www.trainingpeaks.com/blog/finding-your-perfect-run-cadence/)
- [Running Cadence Guide — TrainCalc](https://traincalc.com/guides/running-cadence-guide)
- [Apple Developer: Authorizing access to health data](https://developer.apple.com/documentation/healthkit/authorizing-access-to-health-data)
- [UX Design Patterns for Loading — Pencil and Paper](https://www.pencilandpaper.io/articles/ux-pattern-analysis-loading-feedback)
- [Apple HIG: Segmented Controls](https://developer.apple.com/design/human-interface-guidelines/segmented-controls)
- Codebase analysis: `RunEngineService`, `BPMCacheService`, `SettingsView`, `PlaylistDetailView`, `ContentView`

---
*Feature research for: BeatStep v1.2 The Right Flow — onboarding, playlist state, zone-based running*
*Researched: 2026-03-24*
