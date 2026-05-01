import SwiftUI

// MARK: - 升级版液态玻璃壁纸卡片 (Step 4: 高保真复刻)
struct WallpaperCard: View {
    let wallpaper: Wallpaper
    let onTap: () -> Void
    
    @State private var isHovered = false
    private let cornerRadius: CGFloat = 18

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                imageSection
                infoSection
            }
            .frame(width: 200)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(LiquidGlassColors.primaryPink.opacity(isHovered ? 0.08 : 0.03))
                    }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(isHovered ? 0.35 : 0.2),
                                .white.opacity(0.1),
                                .white.opacity(isHovered ? 0.15 : 0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isHovered ? 1.2 : 0.5
                    )
            }
            .shadow(color: .black.opacity(isHovered ? 0.2 : 0.1), radius: isHovered ? 15 : 5, x: 0, y: 8)
            .scaleEffect(isHovered ? 1.025 : 1.0)
        }
        .buttonStyle(.plain)
        .frame(width: 200)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isHovered)
        .onHover { isHovered = $0 }
    }
    
    // MARK: - 图片区域
    private var imageSection: some View {
        ZStack(alignment: .topLeading) {
            // 缩略图加载（优先使用 thumbnailPath，回退到 filePath）
            Group {
                if let thumbPath = wallpaper.thumbnailPath, !thumbPath.isEmpty,
                   let thumbURL = URL(string: thumbPath) {
                    AsyncImage(url: thumbURL) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().aspectRatio(contentMode: .fill)
                        case .failure:
                            fallbackPlaceholder
                        case .empty:
                            loadingPlaceholder
                        @unknown default:
                            fallbackPlaceholder
                        }
                    }
                } else if let fileURL = URL(string: wallpaper.filePath) {
                    AsyncImage(url: fileURL) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().aspectRatio(contentMode: .fill)
                        case .failure:
                            fallbackPlaceholder
                        case .empty:
                            loadingPlaceholder
                        @unknown default:
                            fallbackPlaceholder
                        }
                    }
                } else {
                    fallbackPlaceholder
                }
            }
            .frame(width: 200, height: 130)
            .clipped()

            // 左上角标签 (分类)
            HStack(spacing: 6) {
                if wallpaper.type == .video, let duration = wallpaper.duration {
                    HStack(spacing: 3) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 8))
                        Text(formatDuration(duration))
                    }
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(.black.opacity(0.4))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(.white.opacity(0.2), lineWidth: 0.5))
                }
                
                tagLabel(text: "SFW", color: .green)
            }
            .padding(10)

            // 右下角分辨率 (悬浮)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text(wallpaper.resolution ?? "N/A")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(.black.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .padding(8)
            }
        }
    }

    // 加载中占位
    private var loadingPlaceholder: some View {
        Rectangle()
            .fill(Color.white.opacity(0.03))
            .overlay { ProgressView().tint(.white.opacity(0.3)) }
    }

    // 加载失败占位图
    private var fallbackPlaceholder: some View {
        Rectangle()
            .fill(Color.white.opacity(0.05))
            .overlay {
                LinearGradient(
                    colors: [
                        Color(hex: "5A7CFF").opacity(0.3),
                        Color(hex: "FF5A7D").opacity(0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
    }
    
    // MARK: - 信息区域
    private var infoSection: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(wallpaper.name.isEmpty ? "未命名壁纸" : wallpaper.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Label("1.2k", systemImage: "eye.fill")
                    Label("456", systemImage: "heart.fill")
                }
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.4))
            }

            Spacer()

            Button(action: {}) {
                Image(systemName: "heart")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(.white.opacity(0.05)))
            }
            .buttonStyle(.plain)
        }
        .frame(width: 200)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
    
    private func tagLabel(text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.6))
            .clipShape(Capsule())
    }
    
    private func formatDuration(_ seconds: Double) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: seconds) ?? "0:00"
    }
}
