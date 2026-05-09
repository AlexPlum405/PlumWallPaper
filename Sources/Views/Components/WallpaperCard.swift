import SwiftUI

// MARK: - Artisan Wallpaper Card (Scheme C: Artisan Gallery)
// 这不仅仅是一个卡片，它是数字画廊中的一个精致展位。

struct WallpaperCard: View {
    private let item: WallpaperPreviewItem
    let onTap: () -> Void
    var onDownload: (() -> Void)? = nil

    @Environment(\.modelContext) private var modelContext
    @State private var isHovered = false
    @State private var downloadStatusVersion = 0
    private let cardCornerRadius: CGFloat = 24

    init(wallpaper: Wallpaper, onTap: @escaping () -> Void, onDownload: (() -> Void)? = nil) {
        self.item = WallpaperPreviewItem(wallpaper: wallpaper)
        self.onTap = onTap
        self.onDownload = onDownload
    }

    init(previewItem: WallpaperPreviewItem, onTap: @escaping () -> Void, onDownload: (() -> Void)? = nil) {
        self.item = previewItem
        self.onTap = onTap
        self.onDownload = onDownload
    }

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
        .onHover { hovering in
            isHovered = hovering
            if hovering {
                prefetchFullResolutionPreview()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .plumDownloadCompleted)) { notification in
            if let remoteId = notification.object as? String, remoteId == item.remoteId {
                downloadStatusVersion += 1
            }
        }
    }
    
    // MARK: - 图片区域 (Gallery Canvas)
    private var imageSection: some View {
        ZStack(alignment: .topLeading) {
            Group {
                if thumbnailCandidateURLs.isEmpty {
                    fallbackPlaceholder
                } else {
                    RemoteThumbnailImage(urls: thumbnailCandidateURLs)
                }
            }
            .frame(width: 220, height: 140)
            .clipped()

            HStack(spacing: 8) {
                if item.type == .video {
                    stateChip(text: "动态", icon: "play.fill", color: LiquidGlassColors.primaryPink)
                }

                if item.source == .downloaded {
                    stateChip(text: "本地", icon: "internaldrive", color: LiquidGlassColors.onlineGreen)
                }
            }
            .padding(12)

            VStack {
                Spacer()
                HStack(alignment: .bottom, spacing: 8) {
                    if item.hasAudio {
                        Image(systemName: "waveform")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.7))
                            .padding(6)
                            .background(Circle().fill(Color.black.opacity(0.3)))
                            .background(.ultraThinMaterial, in: Circle())
                    }

                    if item.isFavorite {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(LiquidGlassColors.primaryPink)
                            .padding(6)
                            .background(Circle().fill(Color.black.opacity(0.3)))
                            .background(.ultraThinMaterial, in: Circle())
                    }

                    Spacer()

                    Text(item.resolution ?? "N/A")
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

            if onDownload != nil {
                VStack {
                    HStack {
                        Button(action: { onDownload?() }) {
                            Image(systemName: isDownloaded ? "checkmark.circle.fill" : "arrow.down.circle")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(isDownloaded ? LiquidGlassColors.onlineGreen : .white.opacity(0.9))
                                .shadow(color: .black.opacity(0.3), radius: 4)
                        }
                        .buttonStyle(.plain)
                        .opacity(isHovered ? 1 : 0)

                        Spacer()
                    }
                    .padding(12)

                    Spacer()
                }
            }
        }
    }
    
    // MARK: - 信息区域 (Gallery Tag)
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item.title.isEmpty ? "Untitled" : item.title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(isHovered ? LiquidGlassColors.textPrimary : LiquidGlassColors.textPrimary)
                .lineLimit(2)

            HStack(spacing: 8) {
                if let resolution = item.resolution {
                    metaChip(icon: "rectangle.expand.vertical", text: resolution, color: LiquidGlassColors.primaryPink)
                }

                if item.fileSize > 0 {
                    metaChip(icon: "externaldrive", text: formatFileSize(item.fileSize), color: LiquidGlassColors.accentGold)
                }

                if item.type == .video, let duration = item.duration {
                    metaChip(icon: "clock", text: formatDuration(duration), color: LiquidGlassColors.primaryViolet)
                }
            }

            HStack(spacing: 12) {
                if let views = item.metadata?.views {
                    Label(formatCount(views), systemImage: "eye")
                }
                if let favorites = item.metadata?.favorites {
                    Label(formatCount(favorites), systemImage: "heart")
                }
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

    private var isDownloaded: Bool {
        guard let remoteId = item.remoteId else {
            return item.source == .downloaded
        }
        return DownloadManager.shared.isAlreadyDownloaded(remoteId: remoteId, context: modelContext) != nil || item.source == .downloaded
    }

    private var sourceLabel: String {
        if let remoteSource = item.remoteSource {
            switch remoteSource {
            case .wallhaven: return "Wallhaven"
            case .fourKWallpapers: return "4K"
            case .pexels: return "Pexels"
            case .unsplash: return "Unsplash"
            case .pixabay: return "Pixabay"
            case .bingDaily: return "Bing"
            case .motionBG: return "MotionBG"
            case .steamWorkshop: return "Workshop"
            case .desktopHut: return "DesktopHut"
            }
        }
        return item.source == .downloaded ? "本地" : "在线"
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
    
    @ViewBuilder
    private func artisanAsyncImage(url: URL) -> some View {
        RemoteThumbnailImage(urls: [url])
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

    private func formatFileSize(_ bytes: Int64) -> String {
        let mb = Double(bytes) / 1024.0 / 1024.0
        if mb >= 1000 {
            return String(format: "%.1fGB", mb / 1024.0)
        }
        return String(format: "%.0fMB", mb)
    }

    private func prefetchFullResolutionPreview() {
        Task {
            await PreviewResourcePipeline.shared.prefetchFullResolution(for: item)
        }
    }

    private func url(from path: String) -> URL? {
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if let url = URL(string: trimmed), url.scheme != nil {
            return url
        }
        return URL(fileURLWithPath: trimmed)
    }

    private var thumbnailCandidateURLs: [URL] {
        var urls: [URL] = []

        let thumbnailURL = item.thumbnailPath.flatMap(url(from:))
        let contentURL = item.filePath.isEmpty ? nil : url(from: item.filePath)

        if item.source != .online {
            appendIfLoadable(thumbnailURL, to: &urls, localOnly: true)

            if item.type != .video {
                appendIfLoadable(contentURL, to: &urls)
                appendIfLoadable(thumbnailURL, to: &urls)
            }

            return urls
        }

        appendIfLoadable(thumbnailURL, to: &urls)

        // 静态图片可降级到原图渲染；视频不行（需要专门的视频帧抽取）。
        if item.type != .video {
            appendIfLoadable(contentURL, to: &urls)
        }

        return urls
    }

    private func appendIfLoadable(_ url: URL?, to urls: inout [URL], localOnly: Bool = false) {
        guard let url else { return }
        if url.isFileURL {
            guard FileManager.default.fileExists(atPath: url.path) else { return }
            urls.append(url)
            return
        }

        guard !localOnly else { return }
        urls.append(url)
    }
}
