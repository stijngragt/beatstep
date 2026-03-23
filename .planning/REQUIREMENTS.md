# Requirements: BeatStep

**Defined:** 2026-03-23
**Core Value:** When you run, your music should move with you — every footstrike landing on the beat.

## v1.1 Requirements

Requirements for milestone v1.1 "Dark by Design". Each maps to roadmap phases.

### Dark Mode

- [ ] **DARK-01**: App enforces dark mode globally (Info.plist + window-level override)
- [ ] **DARK-02**: All light-mode-specific code paths and conditional styling are removed

### Design System

- [ ] **DS-01**: Color tokens defined: accent (electric green), 3 background levels, primary/secondary/tertiary text, success/warning/error states
- [ ] **DS-02**: Typography tokens defined: heading, body, caption scales with SF Pro; numeric display scale with SF Pro Rounded
- [ ] **DS-03**: Spacing and component tokens defined: padding scale, corner radii, component sizing
- [ ] **DS-04**: All existing views migrated from hardcoded colors to design tokens
- [ ] **DS-05**: Design system approved by user before view migration begins

### Navigation

- [ ] **NAV-01**: Bottom tab bar with three tabs: Library, Run, Settings
- [ ] **NAV-02**: Each tab maintains its own navigation state (NavigationStack per tab)
- [ ] **NAV-03**: MiniPlayer persists across all tabs via safeAreaInset
- [ ] **NAV-04**: Run tab shows last-used playlist context when available, otherwise prompts to select a playlist

### Bug Fix

- [ ] **BUG-01**: Playlist view displays correct track count (handles zero/null from Spotify API gracefully)

### Brand

- [ ] **BRAND-01**: App icon designed with dark background and electric green accent mark
- [ ] **BRAND-02**: Wordmark established for in-app identity

## Future Requirements

Deferred to future milestones. Tracked but not in current roadmap.

### Accessibility

- **A11Y-01**: Dynamic Type support across all text styles
- **A11Y-02**: VoiceOver labels for all interactive elements

### Visual Polish

- **VIS-01**: Light mode option (only if user feedback demands it)
- **VIS-02**: Alternate icon variants (light/tinted for iOS 18+ adaptive icons)
- **VIS-03**: Animated SF Symbol tab icons

### UX

- **UX-01**: Onboarding redesign with brand identity
- **UX-02**: Haptic design system synchronized with accent interactions

## Out of Scope

| Feature | Reason |
|---------|--------|
| Light mode support | v1.1 is intentional dark commitment; revisit only if feedback demands it |
| Custom tab bar from scratch | Native TabView with styling achieves the look; custom implementation is fragile across iOS versions |
| Gradient accent colors | Contrast ratio failures on interactive elements; solid accent is cleaner |
| Multiple accent colors per tab | Fragments visual identity; single accent maintains brand coherence |
| Alternate icon variants at launch | One excellent icon > three mediocre ones; defer to polish pass |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| DARK-01 | — | Pending |
| DARK-02 | — | Pending |
| DS-01 | — | Pending |
| DS-02 | — | Pending |
| DS-03 | — | Pending |
| DS-04 | — | Pending |
| DS-05 | — | Pending |
| NAV-01 | — | Pending |
| NAV-02 | — | Pending |
| NAV-03 | — | Pending |
| NAV-04 | — | Pending |
| BUG-01 | — | Pending |
| BRAND-01 | — | Pending |
| BRAND-02 | — | Pending |

**Coverage:**
- v1.1 requirements: 14 total
- Mapped to phases: 0
- Unmapped: 14 ⚠️

---
*Requirements defined: 2026-03-23*
*Last updated: 2026-03-23 after initial definition*
