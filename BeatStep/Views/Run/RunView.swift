import SwiftUI

struct RunView: View {
    let playlist: SpotifyPlaylist
    let tracks: [SpotifyTrack]

    private var cadenceService: CadenceService { .shared }
    private var runEngine: RunEngineService { .shared }

    @State private var tolerance: BPMTolerance = .saved
    @State private var selectedZoneId: Int? = RunZone.selectedZoneId

    var body: some View {
        ZStack {
            // Dark background
            Color.surfaceBase.ignoresSafeArea()

            VStack(spacing: 0) {
                // Main content
                Spacer()
                mainContent
                Spacer()

                // Controls
                controlsSection
                    .padding(.bottom, Spacing.md)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            runEngine.stopRun()
            UIApplication.shared.isIdleTimerDisabled = false
            cadenceService.stopDetecting()
        }
    }

    // MARK: - Main Content

    @ViewBuilder
    private var mainContent: some View {
        if cadenceService.permissionDenied {
            permissionDeniedView
        } else {
            switch cadenceService.state {
            case .idle:
                idleView
            case .detecting:
                detectingView
            case .active:
                activeView
            case .paused:
                pausedView
            }
        }
    }

    // MARK: - State Views

    private var idleView: some View {
        VStack(spacing: Spacing.lg) {
            Text(playlist.name)
                .font(.captionText)
                .foregroundStyle(Color.textSecondary)

            if let zoneId = selectedZoneId,
               let zone = RunZone.saved.first(where: { $0.id == zoneId }) {
                Text(zone.displayLabel)
                    .font(.subheading)
                    .foregroundStyle(Color.textPrimary)
                Text("\(zone.bpm) BPM")
                    .font(.captionText)
                    .foregroundStyle(Color.textSecondary)
            } else {
                Text("Free Run")
                    .font(.subheading)
                    .foregroundStyle(Color.textPrimary)
            }

            Text("Ready to Run")
                .font(.heading)
                .foregroundStyle(Color.textPrimary)

            if selectedZoneId != nil {
                TolerancePicker(tolerance: $tolerance)
                    .padding(.horizontal, Spacing.xl)
            }
        }
    }

    private var detectingView: some View {
        VStack(spacing: Spacing.md) {
            Text(playlist.name)
                .font(.captionText)
                .foregroundStyle(Color.textSecondary)

            Text("Detecting...")
                .font(.heading)
                .foregroundStyle(Color.textPrimary)
                .opacity(0.8)
                .phaseAnimator([false, true]) { content, phase in
                    content.opacity(phase ? 1.0 : 0.4)
                } animation: { _ in
                    .easeInOut(duration: 0.8)
                }

            ProgressView()
                .progressViewStyle(.circular)
                .tint(Color.textPrimary)
                .scaleEffect(1.2)
        }
    }

    private var activeView: some View {
        VStack(spacing: Spacing.md) {
            Text(playlist.name)
                .font(.captionText)
                .foregroundStyle(Color.textSecondary)

            // Phase label for guided mode
            if let phase = runEngine.rampPhase {
                Text(phase.displayLabel)
                    .font(.captionText)
                    .foregroundStyle(Color.textSecondary)
            }

            CadenceDisplayView(
                spm: cadenceService.currentSPM,
                trend: cadenceService.trend
            )
        }
    }

    private var pausedView: some View {
        VStack(spacing: Spacing.md) {
            Text("Paused")
                .font(.heading)
                .foregroundStyle(Color.textTertiary)

            Text("Resume running to continue")
                .font(.captionText)
                .foregroundStyle(Color.textTertiary)

            // Show last known SPM dimmed
            if cadenceService.currentSPM > 0 {
                Text("\(cadenceService.currentSPM)")
                    .font(.displayHero)
                    .foregroundStyle(Color.textTertiary)
                    .padding(.top, Spacing.sm)
            }
        }
    }

    private var permissionDeniedView: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "figure.run.circle")
                .font(.system(size: 48))
                .foregroundStyle(Color.textSecondary)

            Text("Motion Access Required")
                .font(.subheading)
                .foregroundStyle(Color.textPrimary)

            Text("BeatStep needs motion access to detect your running cadence")
                .font(.captionText)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)

            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label("Open Settings", systemImage: "gear")
                    .font(.bodyBold)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.md)
                    .background(Capsule().fill(Color.surfaceOverlay))
                    .foregroundStyle(Color.textPrimary)
            }
        }
    }

    // MARK: - Controls

    /// Computed target BPM from zone selection
    private var targetBPM: Int {
        if let zoneId = selectedZoneId,
           let zone = RunZone.saved.first(where: { $0.id == zoneId }) {
            return zone.bpm
        }
        return RunMode.savedTargetBPM
    }

    @ViewBuilder
    private var controlsSection: some View {
        if cadenceService.state == .idle && !cadenceService.permissionDenied {
            Button {
                if let zoneId = selectedZoneId,
                   let zone = RunZone.saved.first(where: { $0.id == zoneId }) {
                    runEngine.runMode = .guided
                    runEngine.tolerance = tolerance
                    RunMode.savedTargetBPM = zone.bpm
                } else {
                    runEngine.runMode = .free
                    runEngine.tolerance = tolerance
                }
                LastRunPlaylist.name = playlist.name
                LastRunPlaylist.id = playlist.id
                LastRunPlaylist.imageURL = playlist.images?.first?.url
                cadenceService.requestPermissionAndStart()
                UIApplication.shared.isIdleTimerDisabled = true
                Task { await runEngine.startRun(playlist: playlist, tracks: tracks) }
            } label: {
                Label("Start Run", systemImage: "figure.run")
                    .font(.subheading)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.surfaceBase)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(Capsule().fill(Color.stateSuccess))
                    .padding(.horizontal, Spacing.xl)
            }
        } else if cadenceService.state != .idle {
            guidedRunControls
        }
    }

    @ViewBuilder
    private var guidedRunControls: some View {
        if runEngine.runMode == .guided && runEngine.rampPhase != .coolDown {
            // Guided run: show both Cool Down and Stop
            VStack(spacing: Spacing.md) {
                Button {
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

                stopRunButton
            }
        } else {
            // Free run or cool-down already active: just Stop
            stopRunButton
        }
    }

    private var stopRunButton: some View {
        Button {
            runEngine.stopRun()
            cadenceService.stopDetecting()
            UIApplication.shared.isIdleTimerDisabled = false
        } label: {
            Label("Stop Run", systemImage: "stop.fill")
                .font(.bodyBold)
                .foregroundStyle(Color.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .background(Capsule().fill(Color.stateError.opacity(0.8)))
                .padding(.horizontal, Spacing.xl)
        }
    }
}
