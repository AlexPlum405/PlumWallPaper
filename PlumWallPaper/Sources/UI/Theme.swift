import SwiftUI

struct Theme {
    static let bg = Color(hex: "0D0E12")
    static let accent = Color(hex: "E03E3E")
    static let glass = Color.white.opacity(0.04)
    static let glassHeavy = Color.white.opacity(0.08)
    static let border = Color.white.opacity(0.1)
    static let glassBorder = Color.white.opacity(0.1)

    struct Fonts {
        static func display(size: CGFloat, weight: Font.Weight = .regular) -> Font {
            if weight == .semibold || weight == .bold {
                return .custom("CormorantGaramond-SemiBoldItalic", size: size)
            }
            return .custom("CormorantGaramond-Italic", size: size)
        }

        static func ui(size: CGFloat, weight: Font.Weight = .regular) -> Font {
            return .system(size: size, weight: weight, design: .rounded)
        }
    }
}

struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .hudWindow
    var blendingMode: NSVisualEffectView.BlendingMode = .withinWindow

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

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension View {
    func plumGlass(cornerRadius: CGFloat = 12) -> some View {
        self.background(VisualEffectView(material: .underWindowBackground))
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Theme.glassBorder, lineWidth: 1)
            )
    }
}
