import SwiftUI

// MARK: - Artisan Filter Chips (Scheme C: Artisan Gallery)
// 极简的分类索引，采用呼吸感十足的间距与排版暗示。

struct FilterChip: View {
    let title: String
    var isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .kerning(1.0) // 增加字间距，提升画廊感
                .foregroundStyle(isSelected ? LiquidGlassColors.primaryPink : (isHovered ? LiquidGlassColors.textPrimary : LiquidGlassColors.textSecondary))
                .padding(.horizontal, 18)
                .frame(height: 32)
                .background {
                    if isSelected {
                        Capsule()
                            .fill(LiquidGlassColors.primaryPink.opacity(0.1))
                            .overlay(Capsule().stroke(LiquidGlassColors.primaryPink.opacity(0.3), lineWidth: 0.5))
                    } else {
                        Capsule()
                            .fill(Color.white.opacity(isHovered ? 0.05 : 0.02))
                    }
                }
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(.galleryEase, value: isHovered)
        .animation(.gallerySpring, value: isSelected)
    }
}

// MARK: - 画廊分类芯片 (Artisan Category)
struct CategoryChip: View {
    let title: String
    let icon: String
    let colors: [Color]
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                // 极简圆形图标
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .opacity(isSelected ? 0.9 : 0.3)
                    
                    Image(systemName: icon)
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(.white)
                }
                .frame(width: 22, height: 22)
                
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .kerning(0.8)
                    .foregroundStyle(isSelected ? LiquidGlassColors.textPrimary : LiquidGlassColors.textSecondary)
            }
            .padding(.horizontal, 14)
            .frame(height: 40)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(isSelected ? 0.08 : (isHovered ? 0.04 : 0.02)))
                    .overlay {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(colors.first?.opacity(0.4) ?? .clear, lineWidth: 0.5)
                        }
                    }
            }
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .scaleEffect(isHovered ? 1.03 : 1.0)
        .animation(.gallerySpring, value: isHovered)
    }
}
