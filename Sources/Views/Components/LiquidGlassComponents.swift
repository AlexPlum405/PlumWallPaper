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
                .font(.custom("Georgia", size: 18).bold())
                .kerning(1.5)
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
                .font(.custom("Georgia", size: 14).italic())
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
                .font(.custom("Georgia", size: 18).bold())
                .kerning(1.0)
                .foregroundStyle(LiquidGlassColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
