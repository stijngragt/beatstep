import SwiftUI

struct ZonePickerView: View {
    @Binding var selectedZoneIds: Set<Int>

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
        let isSelected = selectedZoneIds.contains(zone.id)
        return Button {
            BSHaptics.selection()
            withAnimation(BSAnimation.snappy) {
                if selectedZoneIds.contains(zone.id) {
                    selectedZoneIds.remove(zone.id)
                } else {
                    selectedZoneIds.insert(zone.id)
                }
            }
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
        .buttonStyle(.plain)
    }

    // MARK: - Free Capsule

    private var freeCapsule: some View {
        let isSelected = selectedZoneIds.isEmpty
        return Button {
            BSHaptics.selection()
            withAnimation(BSAnimation.snappy) {
                selectedZoneIds.removeAll()
            }
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
        .buttonStyle(.plain)
    }
}
