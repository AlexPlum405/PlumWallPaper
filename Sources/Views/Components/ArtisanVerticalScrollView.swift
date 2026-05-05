import SwiftUI

struct ArtisanVerticalScrollView<Content: View>: View {
    private let topInset: CGFloat
    private let bottomInset: CGFloat
    private let trailingInset: CGFloat
    private let content: () -> Content
    private let coordinateSpaceName = "artisanVerticalScrollView-\(UUID().uuidString)"

    @State private var contentHeight: CGFloat = 0
    @State private var scrollOffset: CGFloat = 0
    @State private var isHovering = false
    @State private var isRecentlyScrolling = false
    @State private var scrollPulseTask: Task<Void, Never>?

    init(
        topInset: CGFloat = 104,
        bottomInset: CGFloat = 44,
        trailingInset: CGFloat = 28,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.topInset = topInset
        self.bottomInset = bottomInset
        self.trailingInset = trailingInset
        self.content = content
    }

    var body: some View {
        GeometryReader { viewportProxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    GeometryReader { offsetProxy in
                        Color.clear.preference(
                            key: ArtisanScrollOffsetPreferenceKey.self,
                            value: offsetProxy.frame(in: .named(coordinateSpaceName)).minY
                        )
                    }
                    .frame(height: 0)

                    content()
                }
                .background {
                    GeometryReader { contentProxy in
                        Color.clear.preference(
                            key: ArtisanScrollContentHeightPreferenceKey.self,
                            value: contentProxy.size.height
                        )
                    }
                }
            }
            .coordinateSpace(name: coordinateSpaceName)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.18)) {
                    isHovering = hovering
                }
            }
            .onPreferenceChange(ArtisanScrollOffsetPreferenceKey.self) { value in
                let nextOffset = max(0, -value)
                if abs(nextOffset - scrollOffset) > 0.5 {
                    markRecentlyScrolling()
                }
                scrollOffset = nextOffset
            }
            .onPreferenceChange(ArtisanScrollContentHeightPreferenceKey.self) { value in
                contentHeight = value
            }
            .overlay(alignment: .trailing) {
                scrollIndicator(viewportHeight: viewportProxy.size.height)
                    .padding(.trailing, trailingInset)
                    .allowsHitTesting(false)
            }
        }
    }

    @ViewBuilder
    private func scrollIndicator(viewportHeight: CGFloat) -> some View {
        let overflow = contentHeight - viewportHeight
        let trackHeight = max(0, viewportHeight - topInset - bottomInset)

        if overflow > 1, trackHeight > 48 {
            let isActive = isHovering || isRecentlyScrolling
            let progress = min(max(scrollOffset / overflow, 0), 1)
            let thumbHeight = min(trackHeight, max(48, trackHeight * viewportHeight / max(contentHeight, viewportHeight)))
            let thumbOffset = (trackHeight - thumbHeight) * progress
            let trackWidth: CGFloat = isActive ? 10 : 7
            let visibleOpacity: Double = isActive ? 1 : 0.86

            VStack(spacing: 0) {
                ZStack(alignment: .top) {
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(isActive ? 0.10 : 0.065))
                        .overlay {
                            Capsule(style: .continuous)
                                .stroke(Color.white.opacity(isActive ? 0.18 : 0.10), lineWidth: 0.5)
                        }
                        .frame(width: trackWidth, height: trackHeight)

                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(isActive ? 0.76 : 0.58),
                                    LiquidGlassColors.primaryPink.opacity(isActive ? 0.82 : 0.64)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .overlay {
                            Capsule(style: .continuous)
                                .stroke(Color.white.opacity(isActive ? 0.28 : 0.18), lineWidth: 0.5)
                        }
                        .frame(width: trackWidth, height: thumbHeight)
                        .offset(y: thumbOffset)
                        .shadow(color: LiquidGlassColors.primaryPink.opacity(isActive ? 0.28 : 0.14), radius: 12, y: 5)
                }
                .frame(width: 24, height: trackHeight, alignment: .top)

                Spacer(minLength: 0)
            }
            .padding(.top, topInset)
            .padding(.bottom, bottomInset)
            .opacity(visibleOpacity)
            .animation(.easeInOut(duration: 0.18), value: isActive)
        }
    }

    private func markRecentlyScrolling() {
        scrollPulseTask?.cancel()
        withAnimation(.easeInOut(duration: 0.12)) {
            isRecentlyScrolling = true
        }
        scrollPulseTask = Task {
            try? await Task.sleep(nanoseconds: 900_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.28)) {
                    isRecentlyScrolling = false
                }
            }
        }
    }
}

private struct ArtisanScrollContentHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct ArtisanScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
