import SwiftUI
import HealthKit
import CoreMotion

struct OnboardingHealthView: View {
    let onContinue: () -> Void

    @AppStorage("hasRequestedHealth") private var hasRequestedHealth = false
    @AppStorage("hasRequestedMotion") private var hasRequestedMotion = false
    @State private var permissionsRequested = false

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            // Value framing
            VStack(spacing: Spacing.md) {
                Image(systemName: "figure.run")
                    .font(.system(size: ComponentSize.iconLarge))
                    .foregroundStyle(Color.accent)

                Text("Motion & Health")
                    .font(.heading)
                    .foregroundStyle(Color.textPrimary)

                Text("BeatStep uses your phone's motion sensor to detect your running cadence and match music to your pace.")
                    .font(.bodyText)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            // Action buttons
            VStack(spacing: Spacing.md) {
                if permissionsRequested {
                    continueButton
                } else {
                    allowButton
                }

                Button {
                    onContinue()
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

    // MARK: - Subviews

    private var allowButton: some View {
        Button {
            requestPermissions()
        } label: {
            Text("Allow Permissions")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .background(Color.accent)
                .foregroundStyle(Color.textOnAccent)
                .clipShape(RoundedRectangle(cornerRadius: Radius.pill))
        }
    }

    private var continueButton: some View {
        Button {
            onContinue()
        } label: {
            Text("Continue")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .background(Color.accent)
                .foregroundStyle(Color.textOnAccent)
                .clipShape(RoundedRectangle(cornerRadius: Radius.pill))
        }
    }

    // MARK: - Permissions

    private func requestPermissions() {
        // Motion permission via CadenceService
        CadenceService.shared.requestPermissionAndStart()
        hasRequestedMotion = true

        // HealthKit permission
        if HKHealthStore.isHealthDataAvailable() {
            let store = HKHealthStore()
            let stepType = HKQuantityType(.stepCount)
            store.requestAuthorization(toShare: [], read: [stepType]) { _, _ in
                DispatchQueue.main.async {
                    hasRequestedHealth = true
                    permissionsRequested = true
                }
            }
        } else {
            hasRequestedHealth = true
            permissionsRequested = true
        }
    }
}
