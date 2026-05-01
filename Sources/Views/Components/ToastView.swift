import SwiftUI

// MARK: - Toast 组件（符合 LiquidGlass 设计系统）
struct ToastView: View {
    let message: String
    let type: ToastType

    enum ToastType {
        case success, warning, error, info

        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .error: return "xmark.circle.fill"
            case .info: return "info.circle.fill"
            }
        }

        var color: Color {
            switch self {
            case .success: return LiquidGlassColors.onlineGreen
            case .warning: return .orange
            case .error: return .red
            case .info: return LiquidGlassColors.accentCyan
            }
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type.icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(type.color)

            Text(message)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(Capsule().stroke(type.color.opacity(0.3), lineWidth: 1))
                .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
        }
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
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 60)
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: toast.id)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + toast.duration) {
                        withAnimation {
                            self.toast = nil
                        }
                    }
                }
            }
        }
    }
}
