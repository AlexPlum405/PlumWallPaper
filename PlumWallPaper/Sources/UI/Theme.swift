import SwiftUI

struct Theme {
    static let bg = Color(red: 13/255, green: 14/255, blue: 18/255)
    static let accent = Color(red: 224/255, green: 62/255, blue: 62/255)
    static let glass = Color.white.opacity(0.02)
    static let glassHeavy = Color.white.opacity(0.06)
    static let border = Color.white.opacity(0.05)

    struct Fonts {
        static func display(size: CGFloat) -> Font {
            return .custom("CormorantGaramond-Italic", size: size)
        }

        static func ui(size: CGFloat, weight: Font.Weight = .regular) -> Font {
            return .system(size: size, weight: weight, design: .default)
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

extension View {
    func plumGlass(cornerRadius: CGFloat = 12) -> some View {
        self.background(VisualEffectView(material: .underWindowBackground))
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Theme.border, lineWidth: 1)
            )
    }
}
