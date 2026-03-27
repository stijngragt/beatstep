import SwiftUI

struct CollapsiblePlayerView: View {
    @AppStorage("playerCollapsed") private var isCollapsed = false  // D-10: default expanded, D-11: persists
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false
    @State private var hasPassedThreshold = false  // Prevents multiple haptic fires

    private let expandedHeight = ComponentSize.miniPlayerHeight        // 64
    private let collapsedHeight = ComponentSize.miniPlayerCollapsedHeight  // 20
    private let dragThreshold: CGFloat = 40  // UI-SPEC: half the height difference

    /// Base height at rest (no drag in progress)
    private var baseHeight: CGFloat {
        isCollapsed ? collapsedHeight : expandedHeight
    }

    /// Current height accounting for active drag
    private var currentHeight: CGFloat {
        Self.computeCurrentHeight(
            baseHeight: baseHeight,
            dragOffset: dragOffset,
            isCollapsed: isCollapsed,
            collapsedHeight: collapsedHeight,
            expandedHeight: expandedHeight
        )
    }

    /// 0.0 = fully collapsed, 1.0 = fully expanded
    private var expandProgress: CGFloat {
        Self.computeExpandProgress(
            currentHeight: currentHeight,
            collapsedHeight: collapsedHeight,
            expandedHeight: expandedHeight
        )
    }

    // MARK: - Static testable functions

    /// Computes the current height from drag state. Clamped between collapsed and expanded.
    static func computeCurrentHeight(
        baseHeight: CGFloat,
        dragOffset: CGFloat,
        isCollapsed: Bool,
        collapsedHeight: CGFloat,
        expandedHeight: CGFloat
    ) -> CGFloat {
        let offset = isCollapsed ? -dragOffset : dragOffset
        let target = baseHeight + offset
        return min(max(target, collapsedHeight), expandedHeight)
    }

    /// Computes expand progress: 0.0 = fully collapsed, 1.0 = fully expanded.
    static func computeExpandProgress(
        currentHeight: CGFloat,
        collapsedHeight: CGFloat,
        expandedHeight: CGFloat
    ) -> CGFloat {
        let range = expandedHeight - collapsedHeight
        guard range > 0 else { return 0 }
        return (currentHeight - collapsedHeight) / range
    }

    /// Whether a drag of the given distance should trigger a state toggle.
    static func shouldToggle(dragDistance: CGFloat, threshold: CGFloat) -> Bool {
        abs(dragDistance) > threshold
    }

    var body: some View {
        ZStack {
            // Expanded content layer -- fades out as player collapses
            MiniPlayerView()
                .opacity(expandProgress)
                .allowsHitTesting(expandProgress > 0.5)

            // Collapsed pill handle -- fades in as player collapses
            Capsule()
                .fill(Color.textTertiary)
                .frame(width: ComponentSize.dragHandleWidth,     // 36pt
                       height: ComponentSize.dragHandleHeight)   // 4pt
                .opacity(1 - expandProgress)
        }
        .frame(height: currentHeight)
        .frame(maxWidth: .infinity)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 4, y: -2)
                .opacity(expandProgress)  // Fade out background when collapsed
        )
        .contentShape(Rectangle())
        .gesture(dragGesture)
        .onTapGesture { toggleState() }
        .accessibilityLabel(isCollapsed
            ? "Music player, collapsed. Tap or swipe up to expand."
            : "Music player. Swipe down to minimize.")
    }

    // MARK: - Gestures

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 8)  // UI-SPEC: 8pt minimum
            .onChanged { value in
                // Only commit to vertical drags (Pitfall 1: direction ambiguity)
                guard abs(value.translation.height) > abs(value.translation.width) else { return }
                isDragging = true
                dragOffset = value.translation.height

                // D-04: Haptic at threshold crossing (Pitfall 5: debounced)
                let crossed = Self.shouldToggle(dragDistance: value.translation.height, threshold: dragThreshold)
                if crossed && !hasPassedThreshold {
                    BSHaptics.light()
                    hasPassedThreshold = true
                } else if !crossed && hasPassedThreshold {
                    hasPassedThreshold = false
                }
            }
            .onEnded { value in
                isDragging = false
                hasPassedThreshold = false

                let toggle = Self.shouldToggle(dragDistance: value.translation.height, threshold: dragThreshold)
                if toggle {
                    // Check drag direction matches expected state change
                    let isDraggingDown = value.translation.height > 0
                    if (isDraggingDown && !isCollapsed) || (!isDraggingDown && isCollapsed) {
                        withAnimation(BSAnimation.smooth) {
                            isCollapsed.toggle()
                        }
                    }
                }
                withAnimation(BSAnimation.smooth) {
                    dragOffset = 0
                }
            }
    }

    private func toggleState() {
        BSHaptics.light()  // D-04
        withAnimation(BSAnimation.smooth) {
            isCollapsed.toggle()
        }
    }
}
