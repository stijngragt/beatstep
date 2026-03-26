import SwiftUI

struct TapBPMView: View {
    let track: SpotifyTrack
    let playlistURI: String
    let onSave: (Int) -> Void

    @State private var engine = TapBPMEngine()
    @State private var showTapFlash = false
    @State private var showShake = false
    @Environment(\.dismiss) private var dismiss

    private var completedIntervals: Int {
        min(max(0, engine.tapCount - 1), 8)
    }

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header
            VStack(spacing: Spacing.xs) {
                Text(track.name)
                    .font(.heading)
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)

                Text(track.artistName)
                    .font(.captionText)
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(1)

                HStack(spacing: Spacing.sm) {
                    Text(engine.currentBPM.map { "\($0)" } ?? "--")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.textPrimary)
                        .contentTransition(.numericText())
                        .monospacedDigit()

                    Text("BPM")
                        .font(.captionText)
                        .foregroundStyle(Color.textSecondary)
                }

                Text("\(completedIntervals)/8")
                    .font(.captionText)
                    .foregroundStyle(Color.textSecondary)
            }
            .padding(.top, Spacing.md)
            .padding(.horizontal, Spacing.md)

            // MARK: - Progress Dots
            VStack(spacing: Spacing.xs) {
                HStack(spacing: Spacing.xs) {
                    ForEach(0..<8, id: \.self) { index in
                        Circle()
                            .fill(index < completedIntervals ? Color.accent : Color.surfaceOverlay)
                            .frame(width: 10, height: 10)
                    }
                }

                if engine.isStable {
                    HStack(spacing: Spacing.xxs) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Stable")
                    }
                    .font(.captionText)
                    .foregroundStyle(Color.stateSuccess)
                    .transition(.opacity)
                }
            }
            .padding(.vertical, Spacing.sm)
            .animation(BSAnimation.smooth, value: engine.isStable)

            // MARK: - Tap Zone
            Rectangle()
                .fill(Color.surfaceOverlay)
                .overlay {
                    VStack(spacing: Spacing.sm) {
                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.textTertiary)

                        Text("Tap along with the beat")
                            .font(.bodyText)
                            .foregroundStyle(Color.textSecondary)
                    }
                    .opacity(showTapFlash ? 0.4 : 1.0)
                }
                .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
                .modifier(ShakeModifier(animating: showShake))
                .contentShape(Rectangle())
                .onTapGesture {
                    engine.tap()
                    if engine.lastTapWasOutlier {
                        BSHaptics.error()
                        withAnimation(.default.speed(6)) {
                            showShake = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            showShake = false
                        }
                    } else {
                        BSHaptics.light()
                        withAnimation(BSAnimation.quick) {
                            showTapFlash = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            withAnimation(BSAnimation.quick) {
                                showTapFlash = false
                            }
                        }
                    }
                }
                .padding(.horizontal, Spacing.md)

            // MARK: - Bottom Bar
            HStack {
                Button {
                    BSHaptics.light()
                    engine.reset()
                } label: {
                    Text("Reset")
                        .font(.bodyText)
                        .foregroundStyle(Color.textSecondary)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.sm)
                }

                Spacer()

                Button {
                    save()
                } label: {
                    Text("Save")
                        .font(.bodyText)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.sm)
                        .background(
                            Capsule().fill(engine.canSave ? Color.accent : Color.accent.opacity(0.4))
                        )
                }
                .disabled(!engine.canSave)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
        }
        .onAppear {
            SpotifyPlayerService.shared.play(uri: track.uri, contextURI: playlistURI)
        }
        .onDisappear {
            engine.reset()
        }
    }

    // MARK: - Actions

    private func save() {
        guard let bpm = engine.currentBPM else { return }
        BPMCacheService.shared.cacheManual(
            trackID: track.id,
            name: track.name,
            artist: track.artistName,
            bpm: bpm
        )
        BSHaptics.success()
        onSave(bpm)
        dismiss()
    }
}

// MARK: - Shake Modifier

private struct ShakeModifier: ViewModifier {
    var animating: Bool

    func body(content: Content) -> some View {
        content
            .offset(x: animating ? -6 : 0)
            .animation(
                animating
                    ? .default.repeatCount(3, autoreverses: true).speed(6)
                    : .default,
                value: animating
            )
    }
}
