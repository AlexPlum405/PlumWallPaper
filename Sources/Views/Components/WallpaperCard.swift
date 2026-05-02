import SwiftUI

// MARK: - Artisan Wallpaper Card (Scheme C: Artisan Gallery)
// 这不仅仅是一个卡片，它是数字画廊中的一个精致展位。

struct WallpaperCard: View {
    let wallpaper: Wallpaper
    let onTap: () -> Void
    var onDownload: (() -> Void)? = nil
    
    @State private var isHovered = false
    private let cardCornerRadius: CGFloat = 24

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                imageSection
                infoSection
            }
            // 严格遵循 LAYOUT ORDER RULE
            .frame(width: 220) // 方案 C 增加呼吸感
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
    
    // MARK: - 图片区域 (Gallery Canvas)
    private var imageSection: some View {
        ZStack(alignment: .topLeading) {
            // 壁纸渲染核心 (遵守 ASYNC IMAGE STANDARDS)
            // 只显示缩略图，不显示视频预览
            Group {
                if let thumbPath = wallpaper.thumbnailPath, !thumbPath.isEmpty,
                   let thumbURL = URL(string: thumbPath) {
                    artisanAsyncImage(url: thumbURL)
                } else if let fileURL = URL(string: wallpaper.filePath) {
                    artisanAsyncImage(url: fileURL)
                } else {
                    fallbackPlaceholder
                }
            }
            .frame(width: 220, height: 140)
            .clipped()

            // 艺术标签 (悬浮在画面之上)
            HStack(spacing: 8) {
                if wallpaper.type == .video, let duration = wallpaper.duration {
                    artisanChip(text: formatDuration(duration), icon: "play.fill", color: LiquidGlassColors.accentGold)
                }
                
                // 默认 SFW 标签，使用鼠尾草绿
                artisanChip(text: "SFW", icon: "shield.check.fill", color: LiquidGlassColors.onlineGreen)
            }
            .padding(12)
            .opacity(isHovered ? 1.0 : 0.6)
            
            // 分辨率指示器 (极简，悬停可见)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text(wallpaper.resolution ?? "N/A")
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

            // 收藏指示器 (右下角)
            if wallpaper.isFavorite {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(systemName: "heart.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(LiquidGlassColors.primaryPink)
                            .padding(6)
                            .background(Circle().fill(.ultraThinMaterial))
                    }
                }
                .padding(10)
            }

            // 下载快捷按钮 (悬浮时显示)
            VStack {
                Spacer()
                HStack {
                    Button(action: { onDownload?() }) {
                        Image(systemName: "arrow.down.to.line.compact")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(6)
                            .background(Circle().fill(.ultraThinMaterial))
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
            }
            .padding(10)
            .opacity(isHovered ? 1 : 0)
        }
    }
    
    // MARK: - 信息区域 (Gallery Tag)
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            // 衬线体标题
            Text(wallpaper.name.isEmpty ? "Untitled Art" : wallpaper.name)
                .font(.custom("Georgia", size: 15).bold())
                .foregroundStyle(isHovered ? LiquidGlassColors.primaryPink : LiquidGlassColors.textPrimary)
                .lineLimit(1)
                .kerning(0.5)

            HStack(spacing: 12) {
                if let views = wallpaper.remoteMetadata?.views {
                    Label(formatCount(views), systemImage: "eye")
                }
                if let favorites = wallpaper.remoteMetadata?.favorites {
                    Label(formatCount(favorites), systemImage: "heart")
                }
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
    
    private func formatCount(_ count: Int) -> String {
        if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000)
        }
        if count >= 1_000 {
            return String(format: "%.1fk", Double(count) / 1_000)
        }
        return "\(count)"
    }

    private func formatDuration(_ seconds: Double) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: seconds) ?? "0:00"
    }
}
