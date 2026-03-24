import SwiftUI

struct ZoneSettingsRow: View {
    @Binding var zone: RunZone
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text(zone.displayLabel)
                        .font(.bodyText)
                        .foregroundStyle(Color.textPrimary)
                    Spacer()
                    Text("\(zone.bpm) BPM")
                        .font(.bodyText)
                        .foregroundStyle(Color.textSecondary)
                }
            }

            if isExpanded {
                Stepper(value: $zone.bpm, in: 100...220) {
                    Text("\(zone.bpm) BPM")
                        .font(.subheading)
                        .monospacedDigit()
                }
                .padding(.top, Spacing.sm)
            }
        }
    }
}
