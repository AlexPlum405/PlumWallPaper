import SwiftUI

// MARK: - Plum Studio Design System (Cool Studio Edition)
// 从暖色艺术感收束到冷静、专业的工作台气质。

// MARK: - 颜色系统 (Palette)
enum LiquidGlassColors {
    // 品牌色 - 冷调工作台 (Cool Studio Palette)
    // 注：名称保持兼容，取值整体冷化。
    static let primaryPink = Color(hex: "8AB4FF")    // Ice Blue — 主强调色
    static let accentGold = Color(hex: "B7C7D9")     // Steel Mist — 次要元信息
    static let champagne = Color(hex: "D8E2F2")      // Frost — 浅冷白

    // 状态色 (Muted Status)
    static let onlineGreen = Color(hex: "8FD3B6")    // 薄荷绿
    static let warningOrange = Color(hex: "E7C58A")  // 柔和琥珀
    static let errorRed = Color(hex: "D57A80")       // 哑光红
    static let tertiaryBlue = Color(hex: "7FA8D6")   // 冰川蓝
    static let primaryViolet = Color(hex: "A8A6F2")  // 电光紫

    // 背景色层级 (Studio Depth)
    static let deepBackground = Color(hex: "101114")      // 近黑冷底
    static let surfaceBackground = Color(hex: "161A21")   // 表面层
    static let elevatedBackground = Color(hex: "1F2430")  // 悬浮层

    // 玻璃效果颜色 (Studio Glass)
    static let glassWhiteSubtle = Color.white.opacity(0.03)
    static let glassWhiteRegular = Color.white.opacity(0.06)
    static let glassBorder = Color.white.opacity(0.10)

    // 文字颜色层级 (Studio Standard)
    static let textPrimary: Color = Color.white
    static let textSecondary: Color = Color(hex: "AEB4BF") // 冷中灰
    static let textTertiary: Color = Color.white.opacity(0.45)
    static let textQuaternary: Color = Color.white.opacity(0.22)
}

// MARK: - 间距系统 (Spacing)
enum GallerySpacing {
    static let micro: CGFloat = 4
    static let tiny: CGFloat = 8
    static let small: CGFloat = 12
    static let normal: CGFloat = 24  // 增加基础间距
    static let large: CGFloat = 32
    static let extraLarge: CGFloat = 48
    static let huge: CGFloat = 64
}

// MARK: - 排版系统 (Typography)
enum GalleryTypography {
    // 核心：系统标题，保留力量感与可读性
    static func artisticTitle(_ size: CGFloat = 32) -> Font {
        .system(size: size, weight: .bold, design: .default)
    }

    // 功能：系统默认 SF 字体
    static func functionalText(_ size: CGFloat = 13, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight)
    }
}

// MARK: - 基础背景组件
struct LiquidGlassAtmosphereBackground: View {
    var body: some View {
        ZStack {
            LiquidGlassColors.deepBackground

            // 极简弥散光晕 (冷调版：更低对比，避免干扰内容)
            GeometryReader { geo in
                ZStack {
                    Circle()
                        .fill(LiquidGlassColors.primaryPink.opacity(0.04))
                        .frame(width: geo.size.width * 0.9)
                        .blur(radius: 160)
                        .offset(x: -geo.size.width * 0.3, y: -geo.size.height * 0.3)

                    Circle()
                        .fill(LiquidGlassColors.tertiaryBlue.opacity(0.03))
                        .frame(width: geo.size.width * 0.7)
                        .blur(radius: 140)
                        .offset(x: geo.size.width * 0.4, y: geo.size.height * 0.5)
                }
            }

            // 背景水印 (极度克制)
            VStack {
                Spacer()
                Text("STUDIO")
                    .font(.system(size: 140, weight: .ultraLight, design: .default))
                    .foregroundStyle(Color.white.opacity(0.012))
                    .kerning(30)
                    .padding(.bottom, 60)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Liquid Glass 卡片基础实现
struct LiquidGlassCard<Content: View>: View {
    let cornerRadius: CGFloat
    let padding: CGFloat
    let content: Content

    init(
        padding: CGFloat = GallerySpacing.normal,
        cornerRadius: CGFloat = 24, // 方案 C 核心：大圆角
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .opacity(0.7)
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(LiquidGlassColors.glassBorder, lineWidth: 0.5)
            }
            // 方案 C：深度弥散阴影
            .shadow(color: Color.black.opacity(0.15), radius: 40, x: 0, y: 20)
    }
}

// MARK: - 样式扩展 (Extensions)
extension View {
    // 注入 Georgia 艺术标题样式
    func artisanTitleStyle(size: CGFloat = 32, kerning: CGFloat = 2) -> some View {
        self.font(GalleryTypography.artisticTitle(size))
            .kerning(kerning)
            .foregroundStyle(LiquidGlassColors.textPrimary)
    }
    
    // 快速应用画廊卡片样式
    func galleryCardStyle(radius: CGFloat = 24, padding: CGFloat = 16) -> some View {
        self.padding(padding)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(LiquidGlassColors.surfaceBackground.opacity(0.4))
                    .background(.ultraThinMaterial)
            )
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(LiquidGlassColors.glassBorder, lineWidth: 0.5)
            )
    }
}

// MARK: - 工具
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6: (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default: (r, g, b) = (1, 1, 1)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: 1)
    }
}

// MARK: - macOS 视觉效果 (Visual Effects)
struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
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

// MARK: - 工具

