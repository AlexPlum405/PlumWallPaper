import SwiftUI

// MARK: - Gallery Extensions (Scheme C: Artisan Gallery)
// 包含画廊阴影、优雅曲线及修饰符扩展。

// MARK: - 节流悬停修饰符 (保持工程严谨性)
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
    /// 节流悬停交互
    func throttledHover(interval: TimeInterval = 0.05, action: @escaping (Bool) -> Void) -> some View {
        modifier(ThrottledHoverModifier(throttleInterval: interval, action: action))
    }

    // MARK: - 匠心阴影 (Artisan Shadow)
    /// 方案 C 核心：极长半径的弥散阴影，营造“画廊悬浮感”
    func artisanShadow(color: Color = Color.black.opacity(0.12), radius: CGFloat = 40, x: CGFloat = 0, y: CGFloat = 20) -> some View {
        self.shadow(color: color, radius: radius, x: x, y: y)
    }

    // MARK: - 玻璃装饰修饰符 (画廊重塑版)
    
    func galleryCircleChrome(tint: Color? = nil) -> some View {
        modifier(GalleryChromeModifier(shape: Circle(), tint: tint))
    }

    func galleryCapsuleChrome(tint: Color? = nil) -> some View {
        modifier(GalleryChromeModifier(shape: Capsule(style: .continuous), tint: tint))
    }

    func galleryRoundedRectChrome(cornerRadius: CGFloat = 24, tint: Color? = nil) -> some View {
        modifier(GalleryChromeModifier(shape: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous), tint: tint))
    }
    
    // 兼容旧版命名，内部使用新逻辑
    func detailGlassCircleChrome(tint: Color? = nil) -> some View { galleryCircleChrome(tint: tint) }
    func detailGlassCapsuleChrome(tint: Color? = nil) -> some View { galleryCapsuleChrome(tint: tint) }
    func detailGlassRoundedRectChrome(cornerRadius: CGFloat = 24, tint: Color? = nil) -> some View { galleryRoundedRectChrome(cornerRadius: cornerRadius, tint: tint) }
    func detailGlassCarouselChrome(cornerRadius: CGFloat = 24, tint: Color? = nil) -> some View { galleryRoundedRectChrome(cornerRadius: cornerRadius, tint: tint) }
}

// MARK: - 内部辅助
private struct GalleryChromeModifier<S: Shape>: ViewModifier {
    let shape: S
    let tint: Color?

    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    shape.fill(.ultraThinMaterial)
                    if let tint {
                        shape.fill(tint.opacity(0.08))
                    }
                }
            }
            .overlay {
                shape
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.18),
                                Color.white.opacity(0.06)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            }
            .clipShape(shape)
    }
}

// MARK: - 动画曲线扩展 (Gallery Curves)
extension Animation {
    /// 方案 C 标准曲线：慢速、优雅、带有轻微阻尼的弹性
    static var gallerySpring: Animation {
        .spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)
    }
    
    /// 更平滑的长过渡
    static var galleryEase: Animation {
        .easeInOut(duration: 0.8)
    }
}
