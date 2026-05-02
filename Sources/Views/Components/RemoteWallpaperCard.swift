import SwiftUI

// MARK: - Remote Wallpaper Card (Artisan Gallery)
struct RemoteWallpaperCard: View {
    let wallpaper: RemoteWallpaper
    let onTap: () -> Void

    @State private var isHovered = false
    private let cardCornerRadius: CGFloat = 24

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                imageSection
                infoSection
            }
            .frame(width: 220)
            .background {
                RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                    .fill(LiquidGlassColors.surfaceBackground.opacity(0.6))
                    .background(.ultraThinMaterial)
            }
            .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(isHovered ? 0.2 : 0.1),
                                .white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            }
            .shadow(color: .black.opacity(isHovered ? 0.2 : 0.1), radius: isHovered ? 40 : 15, x: 0, y: isHovered ? 20 : 10)
            .scaleEffect(isHovered ? 1.04 : 1.0)
        }
        .buttonStyle(.plain)
        .animation(.gallerySpring, value: isHovered)
        .onHover { isHovered = $0 }
    }

    // MARK: - 图片区域
    private var imageSection: some View {
        ZStack(alignment: .topLeading) {
            // 壁纸渲染核心
            if let thumbURL = wallpaper.thumbURL {
                artisanAsyncImage(url: thumbURL)
            } else {
                fallbackPlaceholder
            }

            // 艺术标签
            HStack(spacing: 8) {
                artisanChip(
                    text: wallpaper.purity.uppercased(),
                    icon: "shield.check.fill",
                    color: wallpaper.purity == "sfw" ? LiquidGlassColors.onlineGreen : LiquidGlassColors.warningOrange
                )
            }
            .padding(12)
            .opacity(isHovered ? 1.0 : 0.6)

            // 分辨率指示器
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text(wallpaper.resolution)
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.4))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                }
                .padding(10)
            }
            .opacity(isHovered ? 1.0 : 0)
        }
        .frame(width: 220, height: 140)
        .clipped()
    }

    // MARK: - 信息区域
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            // 标题
            Text(wallpaper.tags?.first?.name ?? "Wallpaper \(wallpaper.id)")
                .font(.custom("Georgia", size: 15).bold())
                .foregroundStyle(isHovered ? LiquidGlassColors.primaryPink : LiquidGlassColors.textPrimary)
                .lineLimit(1)
                .kerning(0.5)

            HStack(spacing: 12) {
                Label("\(formatNumber(wallpaper.views))", systemImage: "eye")
                Label("\(formatNumber(wallpaper.favorites))", systemImage: "heart")
                Spacer()
                if isHovered {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(LiquidGlassColors.textQuaternary)
                }
            }
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(LiquidGlassColors.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - 辅助子视图
    private func artisanAsyncImage(url: URL) -> some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image.resizable().aspectRatio(contentMode: .fill)
                    .transition(.opacity.combined(with: .scale(scale: 1.05)))
            case .failure:
                fallbackPlaceholder
            case .empty:
                loadingPlaceholder
            @unknown default:
                fallbackPlaceholder
            }
        }
    }

    private var loadingPlaceholder: some View {
        ZStack {
            Rectangle().fill(LiquidGlassColors.surfaceBackground)
            ProgressView().controlSize(.small).tint(LiquidGlassColors.textQuaternary)
        }
    }

    private var fallbackPlaceholder: some View {
        ZStack {
            Rectangle().fill(LiquidGlassColors.surfaceBackground)
            Image(systemName: "photo.on.rectangle.angled")
                .foregroundStyle(LiquidGlassColors.textQuaternary)
        }
    }

    private func artisanChip(text: String, icon: String? = nil, color: Color) -> some View {
        HStack(spacing: 4) {
            if let icon {
                Image(systemName: icon).font(.system(size: 7))
            }
            Text(text).font(.system(size: 8, weight: .black))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.6))
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 0.5))
    }

    private func formatNumber(_ number: Int) -> String {
        if number >= 1000 {
            return String(format: "%.1fk", Double(number) / 1000.0)
        }
        return "\(number)"
    }
}
