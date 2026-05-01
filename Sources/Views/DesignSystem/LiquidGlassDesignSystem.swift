import SwiftUI

// MARK: - Plum Artisan Design System (Scheme C: Artisan Gallery)
// 这是一个专注于内容、排版与人文呼吸感的设计系统。

// MARK: - 颜色系统 (Palette)
enum LiquidGlassColors {
    // 品牌色 - 匠心版 (Artisan Palette)
    static let primaryPink = Color(hex: "F4C2C2")    // 柔和粉 (Soft Pink)
    static let accentGold = Color(hex: "E5D1B0")     // 燕麦金 (Oatmeal Gold)
    static let champagne = Color(hex: "F7E7CE")      // 香槟色
    
    // 状态色 - 艺术降噪版 (Muted Status)
    static let onlineGreen = Color(hex: "A8D5BA")    // 鼠尾草绿
    static let warningOrange = Color(hex: "EBCB8B")  // 复古黄
    static let errorRed = Color(hex: "BF616A")       // 莫兰迪红
    static let tertiaryBlue = Color(hex: "81A1C1")   // 冰川蓝
    static let primaryViolet = Color(hex: "B4A0E5")  // 丁香紫

    // 背景色层级 (Gallery Depth)
    static let deepBackground = Color(hex: "1C1C1E")     // 基础深色 (macOS Standard)
    static let surfaceBackground = Color(hex: "252528")   // 表面层
    static let elevatedBackground = Color(hex: "2D2D30")  // 悬浮层
    
    // 玻璃效果颜色 (Artisan Glass)
    static let glassWhiteSubtle = Color.white.opacity(0.03)
    static let glassWhiteRegular = Color.white.opacity(0.06)
    static let glassBorder = Color.white.opacity(0.12)

    // 文字颜色层级 (Gallery Standard)
    static let textPrimary: Color = Color.white
    static let textSecondary: Color = Color(hex: "A1A1A1") // 艺术灰 (Studio Gray)
    static let textTertiary: Color = Color.white.opacity(0.4)
    static let textQuaternary: Color = Color.white.opacity(0.2)
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
    // 核心：Georgia 衬线体标题
    static func artisticTitle(_ size: CGFloat = 32) -> Font {
        .custom("Georgia", size: size).bold()
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
            
            // 极简弥散光晕 (Scheme C 标准：极度柔和，避免干扰内容)
            GeometryReader { geo in
                ZStack {
                    Circle()
                        .fill(LiquidGlassColors.primaryPink.opacity(0.06))
                        .frame(width: geo.size.width * 1.0)
                        .blur(radius: 140)
                        .offset(x: -geo.size.width * 0.3, y: -geo.size.height * 0.3)
                    
                    Circle()
                        .fill(LiquidGlassColors.accentGold.opacity(0.04))
                        .frame(width: geo.size.width * 0.8)
                        .blur(radius: 120)
                        .offset(x: geo.size.width * 0.4, y: geo.size.height * 0.5)
                }
            }
            
            // 背景艺术水印 (Artistic Watermark)
            VStack {
                Spacer()
                Text("GALLERY")
                    .font(.custom("Georgia", size: 140).bold())
                    .foregroundStyle(Color.white.opacity(0.015))
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

