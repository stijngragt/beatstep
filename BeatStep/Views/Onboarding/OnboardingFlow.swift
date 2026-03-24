import SwiftUI

struct OnboardingFlow: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 0) {
                    OnboardingSpotifyView(onContinue: { advanceTo(1, proxy: proxy) })
                        .id(0)
                        .containerRelativeFrame([.horizontal])

                    OnboardingHealthView(onContinue: { advanceTo(2, proxy: proxy) })
                        .id(1)
                        .containerRelativeFrame([.horizontal])

                    OnboardingZonesView(onComplete: complete)
                        .id(2)
                        .containerRelativeFrame([.horizontal])
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollDisabled(true)
        }
        .background(Color.surfaceBase)
    }

    // MARK: - Navigation

    private func advanceTo(_ page: Int, proxy: ScrollViewProxy) {
        withAnimation(.easeInOut(duration: 0.35)) {
            proxy.scrollTo(page, anchor: .leading)
        }
        currentPage = page
    }

    private func complete() {
        hasCompletedOnboarding = true
    }
}
