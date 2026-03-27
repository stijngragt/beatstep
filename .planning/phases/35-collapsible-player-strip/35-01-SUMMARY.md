---
phase: 35-collapsible-player-strip
plan: 01
status: complete
started: 2026-03-27
completed: 2026-03-27
---

## Summary

Built CollapsiblePlayerView — a two-state wrapper around MiniPlayerView with interactive drag gesture, cross-fade animation, haptic feedback, and @AppStorage persistence. Wired into ContentView's miniPlayerInset ViewBuilder.

## What Was Built

- **CollapsiblePlayerView.swift** — ZStack wrapper with expand/collapse states, DragGesture with 40pt threshold, spring snap animation via BSAnimation.smooth, haptic feedback via BSHaptics.light() with debounce, @AppStorage("playerCollapsed") persistence
- **Design tokens** — Added ComponentSize.miniPlayerCollapsedHeight (20), dragHandleWidth (36), dragHandleHeight (4), dragHandleCornerRadius (2)
- **ContentView wiring** — Replaced MiniPlayerView() with CollapsiblePlayerView() in miniPlayerInset ViewBuilder
- **Unit tests** — CollapsiblePlayerTests with 11 test cases for computeExpandProgress, shouldToggle, computeCurrentHeight

## Key Decisions

- Material background fades out when collapsing (user feedback: full-width collapsed bar looked bad)
- Used Color.textTertiary for pill handle color (matches design system)
- Static testable functions extracted from view for unit testing without instantiation
- Direction guard prevents horizontal scroll conflicts with drag gesture

## Deviations from Plan

- Background opacity tied to expandProgress (not in original spec, added after user feedback during verification)
- MiniPlayerView.swift unchanged (wrapper pattern preserved as planned)

## Key Files

### Created
- BeatStep/Views/Player/CollapsiblePlayerView.swift
- BeatStepTests/CollapsiblePlayerTests.swift

### Modified
- BeatStep/DesignSystem/DesignTokens.swift
- BeatStepTests/DesignTokenTests.swift
- BeatStep/App/ContentView.swift
- BeatStep.xcodeproj/project.pbxproj

## Commits

- e724f73: feat(35): add collapsible player strip with drag gesture and persistence
