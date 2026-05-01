import SwiftUI

// MARK: - 基础筛选芯片 (Step 5: 通用组件)
struct FilterChip: View {
    let title: String
    var isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(isSelected ? 1.0 : 0.6))
                .padding(.horizontal, 16)
                .frame(height: 32)
                .background {
                    if isSelected {
                        Capsule()
                            .fill(LiquidGlassColors.primaryPink.opacity(0.2))
                            .overlay(Capsule().stroke(LiquidGlassColors.primaryPink.opacity(0.4), lineWidth: 1))
                    } else {
                        Capsule()
                            .fill(.white.opacity(isHovered ? 0.1 : 0.05))
                            .overlay(Capsule().stroke(.white.opacity(0.1), lineWidth: 0.5))
                    }
                }
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

// MARK: - 分类芯片 (带渐变图标)
struct CategoryChip: View {
    let title: String
    let icon: String
    let colors: [Color]
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 20, height: 20)
                    Image(systemName: icon)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                }
                
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(isSelected ? 1.0 : 0.7))
            }
            .padding(.horizontal, 12)
            .frame(height: 36)
            .background {
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay {
                        if isSelected {
                            Capsule().fill(colors.first?.opacity(0.15) ?? .clear)
                        }
                    }
                    .overlay(
                        Capsule()
                            .stroke(isSelected ? colors.first?.opacity(0.4) ?? .white.opacity(0.2) : .white.opacity(0.1), lineWidth: 1)
                    )
            }
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isHovered)
    }
}
