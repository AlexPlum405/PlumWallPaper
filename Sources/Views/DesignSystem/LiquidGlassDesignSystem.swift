import SwiftUI
import Combine

// MARK: - Liquid Glass 设计系统
// 基于 Apple 官方 Liquid Glass API (macOS 26+) 的兼容实现

// MARK: - 颜色系统
enum LiquidGlassColors {
    // 恢复 WaifuX 经典主色调
    static let primaryPink = Color(hex: "FF3366")
    static let secondaryViolet = Color(hex: "8B5CF6")
    static let tertiaryBlue = Color(hex: "3B8BFF")
    static let accentCyan = Color(hex: "00D4FF")
    static let accentOrange = Color(hex: "FF6B35")
    static let onlineGreen = Color(hex: "34D399")
    static let warningOrange = Color(hex: "FF9F43")

    // 背景色
    static let deepBackground = Color(hex: "0D0D0D")
    static let midBackground = Color(hex: "12121F")
    static let surfaceBackground = Color(hex: "1A1A2E")
    static let elevatedBackground = Color(hex: "1E1E28")

    // 玻璃效果颜色
    static let glassWhite = Color.white.opacity(0.26)
    static let glassWhiteLight = Color.white.opacity(0.34)
    static let glassWhiteSubtle = Color.white.opacity(0.18)
    static let glassBorder = Color.white.opacity(0.34)

    // 文字颜色
    static let textPrimary: Color = Color.white
    
    static let textSecondary: Color = Color.white.opacity(0.7)
    
    static let textTertiary: Color = Color.white.opacity(0.5)
    
    static let textQuaternary: Color = Color.white.opacity(0.3)

    // 边框颜色
    static let borderSubtle: Color = Color.white.opacity(0.1)
    
    static let borderDefault: Color = Color.white.opacity(0.2)
    
    static let borderStrong: Color = Color.white.opacity(0.3)

    // 发光色（不随主题变化）
    static let glowPink = Color(hex: "FF3B6B").opacity(0.4)
    static let glowViolet = Color(hex: "9D6FFF").opacity(0.4)
    static let glowBlue = Color(hex: "3B8BFF").opacity(0.4)
}

struct LiquidGlassAtmosphereBackground: View {
    let primary: Color
    let secondary: Color
    let tertiary: Color
    let baseTop: Color
    let baseBottom: Color
    
    init(
        primary: Color = LiquidGlassColors.secondaryViolet,
        secondary: Color = LiquidGlassColors.primaryPink,
        tertiary: Color = LiquidGlassColors.accentCyan,
        baseTop: Color = LiquidGlassColors.midBackground,
        baseBottom: Color = LiquidGlassColors.deepBackground
    ) {
        self.primary = primary
        self.secondary = secondary
        self.tertiary = tertiary
        self.baseTop = baseTop
        self.baseBottom = baseBottom
    }

    var body: some View {
        ZStack {
            // 基础渐变
            LinearGradient(
                colors: [baseTop, baseBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // 主色调光晕
            Circle()
                .fill(primary.opacity(0.22))
                .frame(width: 720, height: 720)
                .blur(radius: 60)
                .offset(x: -180, y: -220)

            Circle()
                .fill(secondary.opacity(0.18))
                .frame(width: 640, height: 640)
                .blur(radius: 60)
                .offset(x: 220, y: -120)

            Circle()
                .fill(tertiary.opacity(0.12))
                .frame(width: 560, height: 560)
                .blur(radius: 50)
                .offset(x: 60, y: 220)
        }
        .ignoresSafeArea()
    }
}

// ... (LiquidGlassCard 等其他组件保持不变)
// MARK: - Liquid Glass 卡片组件
struct LiquidGlassCard<Content: View>: View {
    let variant: GlassVariant
    let cornerRadius: CGFloat
    let padding: CGFloat
    let spacing: CGFloat
    let content: Content

    init(
        padding: CGFloat = 20,
        cornerRadius: CGFloat = 20,
        variant: GlassVariant = .regular,
        spacing: CGFloat = 8,
        @ViewBuilder content: () -> Content
    ) {
        self.variant = variant
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .liquidGlassSurface(
                variant.defaultLevel,
                tint: variant.tintColor,
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
    }
}

enum GlassVariant {
    case regular
    case interactive
    case tinted(Color)
    case prominent
    case clear
}

enum LiquidGlassLevel {
    case subtle
    case regular
    case prominent
    case max

    var material: Material {
        switch self {
        case .subtle: return .ultraThinMaterial
        case .regular: return .regularMaterial
        case .prominent: return .thickMaterial
        case .max: return .ultraThickMaterial
        }
    }

    var fillOpacity: Double {
        switch self {
        case .subtle: return 0.72
        case .regular: return 0.8
        case .prominent: return 0.86
        case .max: return 0.92
        }
    }

    var tintOpacity: Double {
        switch self {
        case .subtle: return 0.04
        case .regular: return 0.08
        case .prominent: return 0.12
        case .max: return 0.16
        }
    }

    var highlightOpacity: Double {
        switch self {
        case .subtle: return 0.03
        case .regular: return 0.05
        case .prominent: return 0.08
        case .max: return 0.11
        }
    }

    var borderOpacity: Double {
        switch self {
        case .subtle: return 0.12
        case .regular: return 0.18
        case .prominent: return 0.26
        case .max: return 0.34
        }
    }
}

private extension GlassVariant {
    var defaultLevel: LiquidGlassLevel {
        switch self {
        case .regular: return .regular
        case .interactive: return .prominent
        case .tinted: return .prominent
        case .prominent: return .max
        case .clear: return .subtle
        }
    }

    var tintColor: Color? {
        switch self {
        case .tinted(let color): return color
        default: return nil
        }
    }
}

@MainActor
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    @Published var themeMode: ThemeMode = .dark
    var isDarkMode: Bool { true }
    private init() {}
}


extension View {
    func liquidGlassSurface(_ level: LiquidGlassLevel = .regular, tint: Color? = nil, in shape: some Shape = RoundedRectangle(cornerRadius: 20, style: .continuous)) -> some View {
        self.background {
            ZStack {
                AnyShape(shape).fill(level.material).opacity(level.fillOpacity)
                if let tint { AnyShape(shape).fill(tint.opacity(level.tintOpacity)) }
                AnyShape(shape).fill(LinearGradient(colors: [Color.white.opacity(level.highlightOpacity), Color.clear], startPoint: .topLeading, endPoint: .bottomTrailing))
            }
        }
        .overlay {
            AnyShape(shape).stroke(LinearGradient(colors: [Color.white.opacity(level.borderOpacity), Color.white.opacity(level.borderOpacity * 0.5)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
        }
    }
    func liquidGlassEffect(_ variant: GlassVariant = .regular) -> some View {
        self.liquidGlassSurface(variant.defaultLevel, tint: variant.tintColor)
    }
}

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
