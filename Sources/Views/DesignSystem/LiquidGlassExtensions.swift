import SwiftUI

// MARK: - 节流悬停修饰符
struct ThrottledHoverModifier: ViewModifier {
    let throttleInterval: TimeInterval
    let action: (Bool) -> Void

    @State private var lastUpdateTime: Date = .distantPast
    @State private var pendingState: Bool?
    @State private var workItem: Task<Void, Never>?

    func body(content: Content) -> some View {
        content
            .onHover { hovering in
                let now = Date()
                let timeSinceLastUpdate = now.timeIntervalSince(lastUpdateTime)

                workItem?.cancel()

                if timeSinceLastUpdate >= throttleInterval {
                    lastUpdateTime = now
                    action(hovering)
                } else {
                    pendingState = hovering
                    workItem = Task {
                        try? await Task.sleep(nanoseconds: UInt64(throttleInterval * 1_000_000_000))
                        guard !Task.isCancelled else { return }
                        await MainActor.run {
                            if let state = pendingState {
                                lastUpdateTime = Date()
                                action(state)
                                pendingState = nil
                            }
                        }
                    }
                }
            }
    }
}

// MARK: - View 扩展
extension View {
    /// 节流悬停
    func throttledHover(interval: TimeInterval = 0.05, action: @escaping (Bool) -> Void) -> some View {
        modifier(ThrottledHoverModifier(throttleInterval: interval, action: action))
    }

    // MARK: - 玻璃装饰修饰符
    
    func detailGlassCircleChrome(tint: Color? = nil, level: LiquidGlassLevel = .max) -> some View {
        modifier(DetailGlassChromeModifier(shape: Circle(), tint: tint, level: level))
    }

    func detailGlassCapsuleChrome(tint: Color? = nil, level: LiquidGlassLevel = .max) -> some View {
        modifier(DetailGlassChromeModifier(shape: Capsule(style: .continuous), tint: tint, level: level))
    }

    func detailGlassRoundedRectChrome(cornerRadius: CGFloat = 18, tint: Color? = nil, level: LiquidGlassLevel = .prominent) -> some View {
        modifier(DetailGlassChromeModifier(shape: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous), tint: tint, level: level))
    }

    func detailGlassCarouselChrome(cornerRadius: CGFloat = 28, tint: Color? = nil, level: LiquidGlassLevel = .prominent) -> some View {
        modifier(DetailGlassChromeModifier(shape: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous), tint: tint, level: level))
    }
}

// MARK: - 内部辅助
private struct DetailGlassChromeModifier<S: Shape>: ViewModifier {
    let shape: S
    let tint: Color?
    let level: LiquidGlassLevel

    func body(content: Content) -> some View {
        content
            .liquidGlassSurface(level, tint: tint, in: shape)
            .overlay {
                shape
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
    }
}
