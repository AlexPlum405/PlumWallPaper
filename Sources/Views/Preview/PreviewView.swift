import SwiftUI

struct PreviewView: View {
    let wallpaper: Wallpaper
    let onClose: () -> Void
    @State private var isVisible = false

    var body: some View {
        ZStack {
            // 毛玻璃背板
            Rectangle()
                .fill(.ultraThickMaterial)
                .ignoresSafeArea()
                .onTapGesture { onClose() }

            VStack(spacing: 30) {
                // 主图预览（占位）
                ZStack {
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .fill(LiquidGlassColors.midBackground)
                        .shadow(color: .black.opacity(0.3), radius: 40, x: 0, y: 20)
                    
                    VStack(spacing: 20) {
                        Image(systemName: "photo.artframe")
                            .font(.system(size: 80))
                            .foregroundStyle(LiquidGlassColors.primaryPink.opacity(0.5))
                        
                        Text(wallpaper.name)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(maxWidth: 800, maxHeight: 450)
                .padding(.horizontal, 40)

                // 操作按钮栏
                HStack(spacing: 25) {
                    // 返回
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 60, height: 60)
                            .background(Circle().fill(Color.white.opacity(0.1)))
                    }
                    .buttonStyle(.plain)

                    // 设为壁纸
                    Button(action: onClose) {
                        HStack(spacing: 12) {
                            Image(systemName: "desktopcomputer")
                            Text("设为壁纸")
                                .font(.system(size: 18, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 40)
                        .frame(height: 60)
                        .background(
                            Capsule()
                                .fill(LinearGradient(colors: [LiquidGlassColors.primaryPink, LiquidGlassColors.secondaryViolet], startPoint: .leading, endPoint: .trailing))
                        )
                        .shadow(color: LiquidGlassColors.primaryPink.opacity(0.3), radius: 15, y: 8)
                    }
                    .buttonStyle(.plain)

                    // 收藏
                    Button(action: {}) {
                        Image(systemName: wallpaper.isFavorite ? "heart.fill" : "heart")
                            .font(.system(size: 20))
                            .foregroundStyle(wallpaper.isFavorite ? LiquidGlassColors.primaryPink : .white)
                            .frame(width: 60, height: 60)
                            .background(Circle().fill(Color.white.opacity(0.1)))
                    }
                    .buttonStyle(.plain)
                }
            }
            .scaleEffect(isVisible ? 1 : 0.9)
            .opacity(isVisible ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isVisible = true
            }
        }
    }
}
