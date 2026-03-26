import SwiftUI

struct ActiveRunView: View {
    let playlist: SpotifyPlaylist
    let tracks: [SpotifyTrack]
    var selectedZoneIds: Set<Int> = []

    @Environment(\.dismiss) private var dismiss

    private var cadenceService: CadenceService { .shared }
    private var runEngine: RunEngineService { .shared }
    private var playerService: SpotifyPlayerService { .shared }

    // MARK: - Derived State

    private var zoneName: String? {
        let zones = RunZone.saved.filter { selectedZoneIds.contains($0.id) }
        guard !zones.isEmpty else { return nil }
        if zones.count == 1 { return zones[0].displayLabel }
        return "\(zones.first!.displayLabel)-\(zones.last!.displayLabel)"
    }

    private var targetBPM: Int {
        let zones = RunZone.saved.filter { selectedZoneIds.contains($0.id) }
        guard !zones.isEmpty else { return RunMode.savedTargetBPM }
        let floor = zones.map(\.bpm).min()!
        let ceiling = zones.map(\.bpm).max()!
        return (floor + ceiling) / 2
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.surfaceBase.ignoresSafeArea()

            VStack(spacing: 0) {
                // Zone 1: Status bar
                RunStatusBar(zoneName: zoneName, syncQuality: runEngine.syncQuality)

                Spacer()

                // Zone 2: Hero cadence area
                VStack(spacing: Spacing.md) {
                    if runEngine.runMode == .guided, let phase = runEngine.rampPhase {
                        RampPhaseIndicator(
                            rampPhase: phase,
                            effectiveBPM: runEngine.effectiveBPM,
                            targetBPM: targetBPM
                        )
                        .padding(.horizontal, Spacing.xl)
                        .transition(.opacity)
                    }

                    CadenceDisplayView(
                        spm: cadenceService.currentSPM,
                        trend: cadenceService.trend,
                        syncQuality: runEngine.syncQuality,
                        cadenceDelta: runEngine.cadenceDelta,
                        isGuidedMode: runEngine.runMode == .guided
                    )

                    if runEngine.runMode == .guided {
                        ZoneBandView(
                            targetBPM: targetBPM,
                            toleranceRange: runEngine.tolerance.range,
                            currentCadence: runEngine.adjustedCadence,
                            syncQuality: runEngine.syncQuality
                        )
                        .padding(.horizontal, Spacing.xl)
                        .transition(.opacity)
                    }
                }
                .animation(BSAnimation.smooth, value: runEngine.runMode)

                Spacer()

                // Zone 3: Player + Controls + Stop
                VStack(spacing: Spacing.md) {
                    if let track = runEngine.currentMatchedTrack {
                        RunPlayerView(
                            track: track,
                            isPaused: playerService.isPaused,
                            trackBPM: runEngine.currentTrackBPM,
                            onPlayPause: { playerService.togglePlayPause() },
                            onSkip: { Task { await runEngine.skipToNextMatch() } }
                        )
                        .padding(.horizontal, Spacing.md)
                        .transition(.opacity)
                    }
                    .animation(BSAnimation.smooth, value: runEngine.currentMatchedTrack != nil)

                    // Tempo mode toggle
                    Button {
                        BSHaptics.light()
                        let newMode: TempoMode = runEngine.tempoMode == .oneToOne ? .half : .oneToOne
                        runEngine.tempoMode = newMode
                        newMode.save()
                    } label: {
                        Label("Tempo \(runEngine.tempoMode.displayName)", systemImage: "metronome")
                            .font(.bodyBold)
                            .foregroundStyle(Color.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.md)
                            .background(Capsule().fill(Color.surfaceOverlay))
                            .padding(.horizontal, Spacing.xl)
                    }

                    // Cool Down button (guided mode only, not during cool down)
                    if runEngine.runMode == .guided && runEngine.rampPhase != .coolDown {
                        Button {
                            BSHaptics.light()
                            runEngine.startCoolDown()
                        } label: {
                            Label("Cool Down", systemImage: "arrow.down.heart")
                                .font(.bodyBold)
                                .foregroundStyle(Color.textPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Spacing.md)
                                .background(Capsule().fill(Color.stateWarning.opacity(0.8)))
                                .padding(.horizontal, Spacing.xl)
                        }
                        .transition(.opacity)
                    }
                    .animation(BSAnimation.smooth, value: runEngine.rampPhase)

                    LongPressStopButton(onStop: stopRun)
                        .padding(.bottom, Spacing.lg)
                }
            }
            .syncBackground(runEngine.syncQuality)
        }
    }

    // MARK: - Actions

    private func stopRun() {
        runEngine.stopRun()
        cadenceService.stopDetecting()
        UIApplication.shared.isIdleTimerDisabled = false
        dismiss()
    }
}

// MARK: - Previews

#Preview("Active Run") {
    ActiveRunView(
        playlist: SpotifyPlaylist(
            id: "1", name: "Running Hits", description: nil, images: nil,
            tracks: TracksRef(total: 50),
            owner: PlaylistOwner(displayName: "Spotify")
        ),
        tracks: [],
        selectedZoneIds: []
    )
}
