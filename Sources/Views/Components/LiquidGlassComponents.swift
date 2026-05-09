import SwiftUI
import AppKit

// MARK: - Artisan Progress Indicator
struct CustomProgressView: View {
    var tint: Color = LiquidGlassColors.primaryPink
    var scale: CGFloat = 1.0
    
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(tint.opacity(0.1), lineWidth: 1.5)
                .frame(width: 24 * scale, height: 24 * scale)
            
            Circle()
                .trim(from: 0, to: 0.3)
                .stroke(tint, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                .frame(width: 24 * scale, height: 24 * scale)
                .rotationEffect(Angle(degrees: rotation))
        }
        .onAppear {
            withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

// MARK: - 液态玻璃背景 (macOS 26 标准)
struct LiquidGlassBackgroundView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    init(material: NSVisualEffectView.Material = .hudWindow, blendingMode: NSVisualEffectView.BlendingMode = .behindWindow) {
        self.material = material
        self.blendingMode = blendingMode
    }

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

// MARK: - Artisan Section Header
struct LiquidGlassSectionHeader: View {
    let title: String
    let icon: String?
    let color: Color

    init(title: String, icon: String? = nil, color: Color = LiquidGlassColors.primaryPink) {
        self.title = title
        self.icon = icon
        self.color = color
    }

    var body: some View {
        HStack(spacing: 12) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(color)
            }
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .kerning(0.6)
                .foregroundStyle(LiquidGlassColors.textPrimary)
            Spacer()
        }
    }
}

// MARK: - 极简分隔线
struct GlassDivider: View {
    var body: some View {
        Rectangle()
            .fill(LiquidGlassColors.glassBorder.opacity(0.5))
            .frame(height: 0.5)
            .padding(.vertical, 8)
    }
}

// MARK: - 画廊导航按钮
struct LiquidGlassNavButton: View {
    var title: String
    var icon: String
    var isSelected: Bool
    var color: Color
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .frame(width: 24)
                    .foregroundStyle(isSelected ? color : LiquidGlassColors.textSecondary)

                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .kerning(0.5)
                    .foregroundStyle(isSelected ? LiquidGlassColors.textPrimary : LiquidGlassColors.textSecondary)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background {
                if isSelected || isHovered {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(isSelected ? color.opacity(0.12) : Color.white.opacity(0.05))
                        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(isSelected ? color.opacity(0.3) : Color.clear, lineWidth: 0.5))
                }
            }
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(.gallerySpring, value: isHovered)
        .animation(.gallerySpring, value: isSelected)
    }
}

// MARK: - 画廊加载视图
struct LiquidGlassLoadingView: View {
    var message: String

    var body: some View {
        VStack(spacing: 20) {
            CustomProgressView(tint: LiquidGlassColors.primaryPink, scale: 1.5)
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(LiquidGlassColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 画廊空状态视图
struct LiquidGlassEmptyState: View {
    var message: String
    var icon: String

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: icon)
                .font(.system(size: 64, weight: .ultraLight))
                .foregroundStyle(LiquidGlassColors.textQuaternary)

            Text(message)
                .font(.system(size: 18, weight: .semibold))
                .kerning(0.4)
                .foregroundStyle(LiquidGlassColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Plum HUD Surface
struct PlumHUDSurface<Content: View>: View {
    var cornerRadius: CGFloat = 28
    var padding: CGFloat = 10
    let content: Content

    init(
        cornerRadius: CGFloat = 28,
        padding: CGFloat = 10,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(LiquidGlassColors.deepBackground.opacity(0.28))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
            )
            .artisanShadow(color: .black.opacity(0.24), radius: 34, y: 18)
    }
}

// MARK: - Plum Action Components
struct PlumPrimaryActionButton: View {
    let title: String
    var icon: String? = nil
    var isBusy: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if isBusy {
                    CustomProgressView(tint: .white, scale: 0.72)
                } else if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .bold))
                }

                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .kerning(0.6)
            }
            .foregroundStyle(.black.opacity(0.86))
            .padding(.horizontal, 28)
            .frame(height: 48)
            .background(
                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [LiquidGlassColors.primaryPink, LiquidGlassColors.tertiaryBlue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .artisanShadow(color: LiquidGlassColors.primaryPink.opacity(0.24), radius: 18, y: 8)
        }
        .buttonStyle(.plain)
        .disabled(isBusy)
    }
}

struct PlumIconActionButton: View {
    let icon: String
    var title: String? = nil
    var isActive: Bool = false
    var isBusy: Bool = false
    var help: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: title == nil ? 0 : 3) {
                if isBusy {
                    CustomProgressView(tint: iconColor, scale: 0.58)
                        .frame(width: 18, height: 18)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 17, weight: .semibold))
                }

                if let title {
                    Text(title)
                        .font(.system(size: 9, weight: .bold))
                        .lineLimit(1)
                }
            }
            .foregroundStyle(iconColor)
            .frame(width: 52, height: 52)
            .background(Circle().fill(isActive ? LiquidGlassColors.primaryPink.opacity(0.14) : Color.white.opacity(0.055)))
            .overlay(Circle().stroke(isActive ? LiquidGlassColors.primaryPink.opacity(0.42) : Color.white.opacity(0.12), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
        .disabled(isBusy)
        .help(help ?? title ?? "")
    }

    private var iconColor: Color {
        isActive ? LiquidGlassColors.primaryPink : .white.opacity(0.66)
    }
}

struct PlumMetadataChip: View {
    let icon: String
    let text: String
    var tint: Color = .white.opacity(0.68)

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
            Text(text)
                .font(.system(size: 10, weight: .bold))
                .lineLimit(1)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 11)
        .frame(height: 26)
        .background(Capsule(style: .continuous).fill(Color.white.opacity(0.095)))
        .overlay(Capsule(style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 0.5))
    }
}

// MARK: - FlowLayout (流式布局)
struct FlowLayout: Layout {
    var spacing: CGFloat

    init(spacing: CGFloat = 12) {
        self.spacing = spacing
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
                self.size.width = max(self.size.width, x - spacing)
            }
            self.size.height = y + rowHeight
        }
    }
}
