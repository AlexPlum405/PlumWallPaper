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
        .onHover { hovering in
            isHovered = hovering
            if hovering {
                prefetchFullResolutionPreview()
            }
        }
    }

    private var imageSection: some View {
        ZStack(alignment: .topLeading) {
            if let thumbURL = wallpaper.thumbURL {
                artisanAsyncImage(url: thumbURL)
            } else {
                fallbackPlaceholder
            }

            HStack(spacing: 8) {
                stateChip(
                    text: wallpaper.purity.uppercased(),
                    icon: "shield.check.fill",
                    color: wallpaper.purity == "sfw" ? LiquidGlassColors.onlineGreen : LiquidGlassColors.warningOrange
                )
            }
            .padding(12)

            VStack {
                Spacer()
                HStack {
                    Spacer()

                    Text(wallpaper.resolution)
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.white.opacity(0.82))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.22))
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                }
                .padding(10)
            }
        }
        .frame(width: 220, height: 140)
        .clipped()
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(wallpaper.tags?.first?.name ?? "Wallpaper \(wallpaper.id)")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(LiquidGlassColors.textPrimary)
                .lineLimit(2)

            HStack(spacing: 8) {
                metaChip(icon: "rectangle.expand.vertical", text: wallpaper.resolution, color: LiquidGlassColors.primaryPink)

                if wallpaper.fileSize > 0 {
                    metaChip(icon: "externaldrive", text: formatFileSize(wallpaper.fileSize), color: LiquidGlassColors.accentGold)
                }
            }

            HStack(spacing: 12) {
                Label("\(formatNumber(wallpaper.views))", systemImage: "eye")
                Label("\(formatNumber(wallpaper.favorites))", systemImage: "heart")
                Spacer()
                Image(systemName: isHovered ? "arrow.up.right" : "circle.fill")
                    .font(.system(size: isHovered ? 10 : 6, weight: .bold))
                    .foregroundStyle(isHovered ? LiquidGlassColors.primaryPink : LiquidGlassColors.textQuaternary)
            }
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(LiquidGlassColors.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private func stateChip(text: String, icon: String? = nil, color: Color) -> some View {
        HStack(spacing: 4) {
            if let icon {
                Image(systemName: icon).font(.system(size: 7, weight: .bold))
            }
            Text(text).font(.system(size: 8, weight: .bold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.6))
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 0.5))
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

    // MARK: - 辅助子视图
    private func artisanAsyncImage(url: URL) -> some View {
        RemoteThumbnailImage(urls: [url, wallpaper.fullImageURL].compactMap { $0 })
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

    private func formatFileSize(_ bytes: Int64) -> String {
        let mb = Double(bytes) / 1024.0 / 1024.0
        if mb >= 1000 {
            return String(format: "%.1fGB", mb / 1024.0)
        }
        return String(format: "%.0fMB", mb)
    }

    private func prefetchFullResolutionPreview() {
        Task {
            await PreviewResourcePipeline.shared.prefetchFullResolution(for: wallpaper)
        }
    }
}
