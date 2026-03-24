import SwiftUI

struct OnboardingZonesView: View {
    let onComplete: () -> Void

    private let zones = RunZone.defaults

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            // Value framing
            VStack(spacing: Spacing.md) {
                Image(systemName: "speedometer")
                    .font(.system(size: ComponentSize.iconLarge))
                    .foregroundStyle(Color.accent)

                Text("Running Zones")
                    .font(.heading)
                    .foregroundStyle(Color.textPrimary)

                Text("BeatStep has 5 pace zones from easy jog to fast sprint. Pick a zone and your music matches the pace.")
                    .font(.bodyText)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
            }

            // Zone overview
            VStack(spacing: Spacing.sm) {
                ForEach(zones) { zone in
                    HStack {
                        Text(zone.displayLabel)
                            .font(.bodyBold)
                            .foregroundStyle(Color.textPrimary)
                        Spacer()
                        Text("\(zone.bpm) BPM")
                            .font(.captionText)
                            .foregroundStyle(Color.textSecondary)
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: Radius.sm)
                            .fill(Color.surfaceElevated)
                    )
                }
            }

            Spacer()

            // Action buttons
            VStack(spacing: Spacing.md) {
                Button {
                    onComplete()
                } label: {
                    Text("Get Started")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(Color.accent)
                        .foregroundStyle(Color.textOnAccent)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.pill))
                }

                Button {
                    onComplete()
                } label: {
                    Text("Skip")
                        .font(.bodyText)
                        .foregroundStyle(Color.textSecondary)
                }
            }

            Spacer()
                .frame(height: Spacing.xxl)
        }
        .padding(.horizontal, Spacing.xl)
        .background(Color.surfaceBase)
    }
}
