import SwiftUI

struct ZonePickerView: View {
    @Binding var selectedZoneId: Int?

    private var zones: [RunZone] {
        RunZone.saved
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(zones) { zone in
                    zoneCapsule(zone)
                }
                freeCapsule
            }
            .padding(.horizontal, Spacing.xs)
        }
    }

    // MARK: - Zone Capsule

    private func zoneCapsule(_ zone: RunZone) -> some View {
        let isSelected = selectedZoneId == zone.id
        return Button {
            selectedZoneId = zone.id
        } label: {
            VStack(spacing: Spacing.xxs) {
                Text(zone.displayLabel)
                    .font(.captionBold)
                Text("\(zone.bpm)")
                    .font(.labelText)
                    .foregroundStyle(Color.textSecondary)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(
                Capsule().fill(
                    isSelected ? Color.surfaceOverlay : Color.surfaceElevated
                )
            )
            .foregroundStyle(
                isSelected ? Color.textPrimary : Color.textSecondary
            )
        }
    }

    // MARK: - Free Capsule

    private var freeCapsule: some View {
        let isSelected = selectedZoneId == nil
        return Button {
            selectedZoneId = nil
        } label: {
            Text("Free")
                .font(.captionBold)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .frame(minHeight: 44)
                .background(
                    Capsule().fill(
                        isSelected ? Color.surfaceOverlay : Color.surfaceElevated
                    )
                )
                .foregroundStyle(
                    isSelected ? Color.textPrimary : Color.textSecondary
                )
        }
    }
}
