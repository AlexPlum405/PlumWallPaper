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
        VStack(alignment: .leading, spacing: 6) {
            Text(mediaItem.title)
                .font(.custom("Georgia", size: 15).bold())
                .foregroundStyle(isHovered ? LiquidGlassColors.primaryPink : LiquidGlassColors.textPrimary)
                .lineLimit(1)
                .kerning(0.5)

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

    // MARK: - 辅助方法
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
}
