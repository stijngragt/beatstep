import SwiftUI

struct TolerancePicker: View {
    @Binding var tolerance: BPMTolerance

    var body: some View {
        VStack(spacing: Spacing.xxs) {
            Text("BPM Tolerance")
                .font(.captionText)
                .foregroundStyle(Color.textSecondary)

            HStack(spacing: Spacing.sm) {
                ForEach(BPMTolerance.allCases, id: \.self) { level in
                    Button {
                        BSHaptics.selection()
                        withAnimation(BSAnimation.snappy) {
                            tolerance = level
                        }
                        level.save()
                    } label: {
                        Text(level.displayName)
                            .font(.captionBold)
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.sm)
                            .background(
                                Capsule().fill(
                                    tolerance == level ? Color.surfaceOverlay : Color.surfaceElevated
                                )
                            )
                            .foregroundStyle(
                                tolerance == level ? Color.textPrimary : Color.textSecondary
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
