import SwiftUI

struct RunTabView: View {
    var body: some View {
        ZStack {
            Color.surfaceBase.ignoresSafeArea()

            VStack(spacing: 0) {
                Button {
                    // Phase 8 (NAV-04) adds playlist context and start flow
                } label: {
                    Text("Start Run")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Color.textOnAccent)
                        .padding(.horizontal, Spacing.xl)
                        .padding(.vertical, Spacing.md)
                        .background(Capsule().fill(Color.accent))
                }

                Text("Select a playlist from Library to start")
                    .font(.captionText)
                    .foregroundStyle(Color.textSecondary)
                    .padding(.top, Spacing.sm)
            }
        }
        .navigationTitle("Run")
        .navigationBarTitleDisplayMode(.large)
    }
}
