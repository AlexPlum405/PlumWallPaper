import SwiftUI

// MARK: - Artisan Media Card (Scheme C: Artisan Gallery)
struct MediaCard: View {
    let mediaItem: MediaItem
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
            artisanAsyncImage(url: mediaItem.thumbnailURL)
                .frame(width: 220, height: 140)
                .clipped()

            // 标签
            HStack(spacing: 8) {
                if let duration = mediaItem.durationSeconds {
                    artisanChip(text: formatDuration(duration), icon: "play.fill", color: LiquidGlassColors.accentGold)
                }
                artisanChip(text: "SFW", icon: "shield.check.fill", color: LiquidGlassColors.onlineGreen)
            }
            .padding(12)
            .opacity(isHovered ? 1.0 : 0.6)

            // 分辨率指示器
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text(mediaItem.resolutionLabel)
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
    }

    // MARK: - 信息区域
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(mediaItem.title)
                .font(.custom("Georgia", size: 15).bold())
                .foregroundStyle(isHovered ? LiquidGlassColors.primaryPink : LiquidGlassColors.textPrimary)
                .lineLimit(1)
                .kerning(0.5)

            // 元信息行1：分辨率 + 文件大小
            HStack(spacing: 8) {
                if let exactRes = mediaItem.exactResolution {
                    metaChip(icon: "square.resize", text: exactRes, color: LiquidGlassColors.primaryPink)
                } else {
                    metaChip(icon: "square.resize", text: mediaItem.resolutionLabel, color: LiquidGlassColors.primaryPink)
                }

                if let fileSize = mediaItem.fileSize {
                    metaChip(icon: "doc", text: formatFileSize(fileSize), color: LiquidGlassColors.accentGold)
                }
            }

            // 元信息行2：统计数据
            HStack(spacing: 12) {
                if let views = mediaItem.viewCount {
                    Label("\(formatCount(views))", systemImage: "eye")
                }
                if let favorites = mediaItem.favoriteCount {
                    Label("\(formatCount(favorites))", systemImage: "heart")
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

    private func metaChip(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon).font(.system(size: 7, weight: .bold))
            Text(text).font(.system(size: 9, weight: .bold))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(color.opacity(0.1))
        .clipShape(Capsule())
    }

    // MARK: - 辅助方法
    private func artisanAsyncImage(url: URL) -> some View {
        RemoteThumbnailImage(urls: [url, mediaItem.posterURL].compactMap { $0 })
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

    private func formatDuration(_ seconds: Double) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: seconds) ?? "0:00"
    }

    private func formatCount(_ count: Int) -> String {
        if count >= 1000 {
            return String(format: "%.1fk", Double(count) / 1000.0)
        }
        return "\(count)"
    }

    private func formatFileSize(_ bytes: Int64) -> String {
        let mb = Double(bytes) / 1024.0 / 1024.0
        if mb >= 1000 {
            return String(format: "%.1fGB", mb / 1024.0)
        }
        return String(format: "%.0fMB", mb)
    }
}
