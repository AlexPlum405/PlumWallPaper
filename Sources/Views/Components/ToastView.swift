import SwiftUI

// MARK: - Artisan Toast (Scheme C: Artisan Gallery)
// 优雅的说明签，如画廊展板般自然浮现。

struct ToastView: View {
    let message: String
    let type: ToastType

    enum ToastType {
        case success, warning, error, info

        var icon: String {
            switch self {
            case .success: return "checkmark.seal.fill"
            case .warning: return "exclamationmark.octagon.fill"
            case .error: return "xmark.seal.fill"
            case .info: return "info.bubble.fill"
            }
        }

        var color: Color {
            switch self {
            case .success: return LiquidGlassColors.onlineGreen
            case .warning: return LiquidGlassColors.warningOrange
            case .error: return LiquidGlassColors.errorRed
            case .info: return LiquidGlassColors.tertiaryBlue
            }
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: type.icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(type.color)

            Text(message)
                .font(.system(size: 13, weight: .bold))
                .kerning(0.5)
                .foregroundStyle(LiquidGlassColors.textPrimary)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(type.color.opacity(0.3), lineWidth: 0.5))
        }
        .artisanShadow()
    }
}

// MARK: - Toast Modifier
struct ToastModifier: ViewModifier {
    @Binding var toast: ToastConfig?

    func body(content: Content) -> some View {
        ZStack {
            content

            if let toast = toast {
                VStack {
                    Spacer()
                    ToastView(message: toast.message, type: toast.type)
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity).combined(with: .scale(scale: 0.9)),
                            removal: .opacity.combined(with: .scale(scale: 0.95))
                        ))
                        .padding(.bottom, 60)
                        .id(toast.id)
                }
                .animation(.gallerySpring, value: toast.id)
            }
        }
        .onChange(of: toast?.id) { _, newId in
            guard let newId = newId, let t = toast else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + t.duration) {
                if self.toast?.id == newId {
                    withAnimation(.galleryEase) { self.toast = nil }
                }
            }
        }
    }
}
