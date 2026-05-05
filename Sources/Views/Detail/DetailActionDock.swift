import SwiftUI

struct DetailActionDock: View {
    let isFavorite: Bool
    let isApplying: Bool
    let isStudioActive: Bool
    let isDownloading: Bool
    let onFavorite: () -> Void
    let onApply: () -> Void
    let onToggleStudio: () -> Void
    let onDownload: () -> Void

    var body: some View {
        HStack(spacing: 24) {
            actionCircleButton(
                icon: isFavorite ? "heart.fill" : "heart",
                color: isFavorite ? LiquidGlassColors.primaryPink : .white.opacity(0.6),
                action: onFavorite
            )

            Button(action: onApply) {
                HStack(spacing: 16) {
                    if isApplying {
                        CustomProgressView(tint: .white, scale: 0.8)
                    } else {
                        Text("设为壁纸")
                            .font(.system(size: 14, weight: .bold))
                            .kerning(2)
                    }
                }
                .padding(.horizontal, 60)
                .frame(height: 52)
                .background(LiquidGlassColors.primaryPink)
                .clipShape(Capsule())
                .foregroundStyle(.black)
                .artisanShadow(color: LiquidGlassColors.primaryPink.opacity(0.3), radius: 20)
            }
            .buttonStyle(.plain)
            .disabled(isApplying)

            Button(action: onToggleStudio) {
                VStack(spacing: 4) {
                    Image(systemName: "camera.aperture")
                        .font(.system(size: 18))
                    Text("实验室")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundStyle(isStudioActive ? LiquidGlassColors.primaryPink : .white.opacity(0.6))
                .frame(width: 52, height: 52)
                .background(Circle().fill(Color.white.opacity(0.05)))
                .overlay(
                    Circle()
                        .stroke(
                            isStudioActive ? LiquidGlassColors.primaryPink.opacity(0.5) : Color.white.opacity(0.1),
                            lineWidth: 1
                        )
                )
            }
            .buttonStyle(.plain)

            actionCircleButton(
                icon: "arrow.down.to.line.compact",
                color: .white.opacity(0.6),
                action: onDownload
            )
            .disabled(isDownloading)
        }
        .padding(12)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 0.5))
        .artisanShadow(color: .black.opacity(0.2), radius: 30)
    }

    private func actionCircleButton(icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(color)
                .frame(width: 52, height: 52)
                .background(Circle().fill(Color.white.opacity(0.05)))
                .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
