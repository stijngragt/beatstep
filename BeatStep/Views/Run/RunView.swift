import SwiftUI

struct RunView: View {
    let playlist: SpotifyPlaylist
    let tracks: [SpotifyTrack]

    private var cadenceService: CadenceService { .shared }
    private var runEngine: RunEngineService { .shared }

    @State private var tolerance: BPMTolerance = .saved

    var body: some View {
        ZStack {
            // Dark background
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Main content
                Spacer()
                mainContent
                Spacer()

                // Controls
                controlsSection
                    .padding(.bottom, 16)

                // Mini-player
                MiniPlayerView()
            }
        }
        .preferredColorScheme(.dark)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
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
        VStack(spacing: 24) {
            Text(playlist.name)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))

            Text("Ready to Run")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.white)

            TolerancePicker(tolerance: $tolerance)
                .padding(.horizontal, 32)
        }
    }

    private var detectingView: some View {
        VStack(spacing: 16) {
            Text(playlist.name)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))

            Text("Detecting...")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.white)
                .opacity(0.8)
                .phaseAnimator([false, true]) { content, phase in
                    content.opacity(phase ? 1.0 : 0.4)
                } animation: { _ in
                    .easeInOut(duration: 0.8)
                }

            ProgressView()
                .progressViewStyle(.circular)
                .tint(.white)
                .scaleEffect(1.2)
        }
    }

    private var activeView: some View {
        VStack(spacing: 16) {
            Text(playlist.name)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))

            CadenceDisplayView(
                spm: cadenceService.currentSPM,
                trend: cadenceService.trend
            )
        }
    }

    private var pausedView: some View {
        VStack(spacing: 12) {
            Text("Paused")
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(.white.opacity(0.4))

            Text("Resume running to continue")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.3))

            // Show last known SPM dimmed
            if cadenceService.currentSPM > 0 {
                Text("\(cadenceService.currentSPM)")
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.2))
                    .padding(.top, 8)
            }
        }
    }

    private var permissionDeniedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.run.circle")
                .font(.system(size: 48))
                .foregroundStyle(.white.opacity(0.5))

            Text("Motion Access Required")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)

            Text("BeatStep needs motion access to detect your running cadence")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label("Open Settings", systemImage: "gear")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(.white.opacity(0.2)))
                    .foregroundStyle(.white)
            }
        }
    }

    // MARK: - Controls

    @ViewBuilder
    private var controlsSection: some View {
        if cadenceService.state == .idle && !cadenceService.permissionDenied {
            Button {
                runEngine.tolerance = tolerance
                cadenceService.requestPermissionAndStart()
                UIApplication.shared.isIdleTimerDisabled = true
                Task { await runEngine.startRun(playlist: playlist, tracks: tracks) }
            } label: {
                Label("Start Run", systemImage: "figure.run")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Capsule().fill(.green))
                    .padding(.horizontal, 40)
            }
        } else if cadenceService.state != .idle {
            Button {
                runEngine.stopRun()
                cadenceService.stopDetecting()
                UIApplication.shared.isIdleTimerDisabled = false
            } label: {
                Label("Stop Run", systemImage: "stop.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(.red.opacity(0.8)))
                    .padding(.horizontal, 40)
            }
        }
    }
}
