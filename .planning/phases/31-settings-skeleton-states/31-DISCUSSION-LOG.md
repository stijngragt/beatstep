# Phase 31: Settings + Skeleton States - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-03-26
**Phase:** 31-settings-skeleton-states
**Areas discussed:** Skeleton design, Settings visual treatment, Skeleton coverage scope

---

## Skeleton Design

### Shimmer style

| Option | Description | Selected |
|--------|-------------|----------|
| Gradient sweep | Classic iOS shimmer — light gradient sweeps left-to-right across grey placeholder shapes | ✓ |
| Pulse opacity | Placeholder shapes pulse between two opacity levels. Simpler, subtler | |
| You decide | Claude picks based on dark UI and animation tokens | |

**User's choice:** Gradient sweep
**Notes:** Standard iOS pattern, used by Spotify and Apple News

### Shape fidelity

| Option | Description | Selected |
|--------|-------------|----------|
| Content-matched | Skeleton mimics real layout — square for art, lines for title/subtitle | ✓ |
| Generic blocks | Simple repeating rectangles, no content structure hinted | |
| You decide | Claude picks based on existing layouts | |

**User's choice:** Content-matched
**Notes:** Reduces layout shift, feels intentional

### Skeleton color

| Option | Description | Selected |
|--------|-------------|----------|
| Neutral grey | Dark grey shapes (~#2A2A2A), shimmer highlight (~#3A3A3A) | ✓ |
| Accent-tinted | Faint heartbeat red tint in shimmer highlight | |
| You decide | Claude picks for dark UI | |

**User's choice:** Neutral grey
**Notes:** Subtle, stays out of the way

### Row count

| Option | Description | Selected |
|--------|-------------|----------|
| Fill visible area | Enough skeleton rows to fill screen height (~6-8 rows) | ✓ |
| Fixed 3-4 rows | Small fixed number, leaves empty space on taller screens | |
| You decide | Claude picks based on device sizes | |

**User's choice:** Fill visible area

---

## Settings Visual Treatment

### Section structure

| Option | Description | Selected |
|--------|-------------|----------|
| Grouped inset list | Standard iOS grouped List style — rounded section cards with headers | ✓ |
| Custom cards | Custom-styled section cards with app's dark design system | |
| You decide | Claude picks for dark UI | |

**User's choice:** Grouped inset list

### Section icons

| Option | Description | Selected |
|--------|-------------|----------|
| No icons | Clean text-only section headers, matches current minimalism | |
| SF Symbol icons | Small colored SF Symbols next to each section header | ✓ |
| You decide | Claude picks based on existing patterns | |

**User's choice:** SF Symbol icons

### Icon color

| Option | Description | Selected |
|--------|-------------|----------|
| All heartbeat red | Consistent single-accent, every icon uses #FF4545 | ✓ |
| Per-section colors | Each section gets a distinct color like Apple Settings | |
| You decide | Claude picks for BeatStep's dark UI | |

**User's choice:** All heartbeat red
**Notes:** Maintains single-accent brand consistency

### Zones layout

| Option | Description | Selected |
|--------|-------------|----------|
| Sub-page | NavigationLink to dedicated zone editing view, keeps Settings compact | ✓ |
| Keep inline | Zones stay expanded in main list | |
| You decide | Claude picks based on scroll depth | |

**User's choice:** Sub-page

---

## Skeleton Coverage Scope

### View coverage (multi-select)

| Option | Description | Selected |
|--------|-------------|----------|
| PlaylistListView | Library playlist list — most visible loading state | ✓ |
| PlaylistDetailView | Track list inside a playlist | ✓ |
| RunTabView | Run tab loading when restoring last playlist | |
| Onboarding views | OnboardingPlaylistView and OnboardingSpotifyView | |

**User's choice:** PlaylistListView and PlaylistDetailView
**Notes:** Focused on the two highest-impact Library views

### Skeleton-to-content transition

| Option | Description | Selected |
|--------|-------------|----------|
| Fade crossfade | Skeleton fades out as content fades in, uses BSAnimation.smooth | ✓ |
| Instant swap | Immediate replacement, snappier but can feel jarring | |
| You decide | Claude picks based on BSAnimation tokens | |

**User's choice:** Fade crossfade

---

## Claude's Discretion

- Exact SF Symbol names for each settings section
- Shimmer animation timing and gradient width
- Skeleton row spacing and corner radii
- Whether "Disconnect Spotify" stays in Account or gets its own section

## Deferred Ideas

None — discussion stayed within phase scope
