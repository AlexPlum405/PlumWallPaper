import SwiftUI
import SwiftData

// MARK: - Media Detail View
struct MediaDetailView: View {
    @State var mediaItem: MediaItem
    var onPrevious: ((@escaping (MediaItem) -> Void) -> Void)? = nil
    var onNext: ((@escaping (MediaItem) -> Void) -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var selectedDownloadOption: MediaDownloadOption?
    @State private var isDownloading = false
    @State private var toast: ToastConfig?
    @State private var isLeftEdgeHovered = false
    @State private var isRightEdgeHovered = false
    @StateObject private var downloadManager = DownloadManager.shared

    var body: some View {
        ZStack {
            // 背景
            fullscreenCanvas

            // 侧翼导航
            sideNavigationArrows

            // 内容层
            VStack(spacing: 0) {
                // 顶部栏
                topBar

                Spacer()

                // 底部信息面板
                infoPanel
            }
        }
        .frame(minWidth: 1000, minHeight: 700)
        .preferredColorScheme(.dark)
        .overlay(alignment: .bottomLeading) {
            DownloadProgressOverlay(downloadManager: downloadManager)
        }
        .onAppear {
            NSLog("[MediaDetailView] 显示详情页")
            NSLog("[MediaDetailView] 标题: \(mediaItem.title)")
            NSLog("[MediaDetailView] fullVideoURL: \(mediaItem.fullVideoURL?.absoluteString ?? "nil")")
            NSLog("[MediaDetailView] previewVideoURL: \(mediaItem.previewVideoURL?.absoluteString ?? "nil")")
            NSLog("[MediaDetailView] thumbnailURL: \(mediaItem.thumbnailURL.absoluteString)")
        }
        .toast($toast)
    }

    // MARK: - 全屏画布
    private var fullscreenCanvas: some View {
        ZStack {
            // 背景模糊
            AsyncImage(url: mediaItem.thumbnailURL) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .blur(radius: 20)
                        .opacity(0.3)
                } else {
                    Color.black
                }
            }

            // 主视频（2K 优先）或图片
            if let videoURL = mediaItem.previewVideoURL ?? mediaItem.fullVideoURL {
                VideoPlayer(url: videoURL, posterURL: mediaItem.thumbnailURL)
            } else {
                AsyncImage(url: mediaItem.thumbnailURL) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        ProgressView()
                            .controlSize(.large)
                            .tint(.white)
                    }
                }
            }

            // 暗角
            RadialGradient(
                colors: [.clear, .black.opacity(0.4)],
                center: .center,
                startRadius: 300,
                endRadius: 1000
            )
        }
        .background(Color.black)
        .ignoresSafeArea()
    }

    // MARK: - 顶部栏
    private var topBar: some View {
        HStack {
            // 标题信息
            VStack(alignment: .leading, spacing: 8) {
                Text(mediaItem.title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)

                HStack(spacing: 16) {
                    Label(mediaItem.sourceName, systemImage: "globe")
                    if let collection = mediaItem.collectionTitle {
                        Label(collection, systemImage: "folder")
                    }
                }
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.7))
            }

            Spacer()

            // 关闭按钮
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.white.opacity(0.8))
                    .symbolRenderingMode(.hierarchical)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 60)
        .padding(.top, 60)
        .background(
            LinearGradient(
                colors: [.black.opacity(0.6), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 200)
            .ignoresSafeArea(edges: .top),
            alignment: .top
        )
    }

    // MARK: - 信息面板
    private var infoPanel: some View {
        VStack(alignment: .leading, spacing: 24) {
            // 基本信息
            HStack(spacing: 32) {
                infoItem(icon: "rectangle.ratio.16.to.9", text: mediaItem.resolutionLabel)
                if let duration = mediaItem.durationLabel {
                    infoItem(icon: "clock", text: duration)
                }
                if let tags = mediaItem.tags.first {
                    infoItem(icon: "tag", text: tags)
                }
            }

            Divider()
                .background(Color.white.opacity(0.2))

            // 下载选项
            if !mediaItem.downloadOptions.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    Text("下载选项")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(mediaItem.downloadOptions) { option in
                                downloadOptionCard(option)
                            }
                        }
                    }
                }
            }

            // 操作按钮
            HStack(spacing: 16) {
                Button {
                    if let option = selectedDownloadOption ?? mediaItem.downloadOptions.first {
                        Task {
                            await startDownload(option)
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        if isDownloading {
                            ProgressView()
                                .controlSize(.small)
                                .tint(.white)
                        } else {
                            Image(systemName: "arrow.down.circle.fill")
                        }
                        Text(isDownloading ? "下载中..." : "下载壁纸")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(LiquidGlassColors.primaryPink)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(mediaItem.downloadOptions.isEmpty || isDownloading)

                Button {
                    NSWorkspace.shared.open(mediaItem.pageURL)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "safari")
                        Text("在浏览器中查看")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 60)
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [.clear, .black.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 400)
            .ignoresSafeArea(edges: .bottom),
            alignment: .bottom
        )
    }

    // MARK: - 辅助视图
    private func infoItem(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
            Text(text)
                .font(.system(size: 14, weight: .medium))
        }
        .foregroundStyle(.white.opacity(0.8))
    }

    private func downloadOptionCard(_ option: MediaDownloadOption) -> some View {
        Button {
            selectedDownloadOption = option
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Text(option.label)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)

                Text(option.detailText)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.7))

                Text(option.fileSizeLabel)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding(16)
            .frame(width: 140)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(selectedDownloadOption?.id == option.id ?
                          LiquidGlassColors.primaryPink.opacity(0.3) :
                          Color.white.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        selectedDownloadOption?.id == option.id ?
                        LiquidGlassColors.primaryPink :
                        Color.white.opacity(0.2),
                        lineWidth: selectedDownloadOption?.id == option.id ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 操作方法
    private func startDownload(_ option: MediaDownloadOption) async {
        guard DownloadManager.shared.isAlreadyDownloaded(remoteId: mediaItem.id, context: modelContext) == nil else {
            toast = ToastConfig(message: "这张动态壁纸已在本地库中", type: .info)
            return
        }

        isDownloading = true
        defer { isDownloading = false }

        do {
            NSLog("[MediaDetailView] 开始下载: \(option.label) - \(option.remoteURL.absoluteString)")
            let wallpaper = try await DownloadManager.shared.downloadWallpaper(
                item: .media(mediaItem),
                quality: option.label,
                downloadURL: option.remoteURL,
                context: modelContext
            )
            let finalURL = URL(fileURLWithPath: wallpaper.filePath)
            NSWorkspace.shared.activateFileViewerSelecting([finalURL])
            toast = ToastConfig(message: "下载完成，已加入本地库", type: .success)

        } catch {
            NSLog("[MediaDetailView] ❌ 下载失败: \(error.localizedDescription)")
            toast = ToastConfig(message: "下载失败: \(error.localizedDescription)", type: .error)
        }
    }

    // MARK: - 侧翼导航箭头
    private var sideNavigationArrows: some View {
        HStack(spacing: 0) {
            // 左箭头
            if onPrevious != nil {
                Button {
                    onPrevious? { newItem in
                        withAnimation(.easeInOut(duration: 0.3)) {
                            mediaItem = newItem
                        }
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 60, height: 120)
                        .background(
                            RoundedRectangle(cornerRadius: 0, style: .continuous)
                                .fill(Color.black.opacity(isLeftEdgeHovered ? 0.6 : 0.3))
                        )
                }
                .buttonStyle(.plain)
                .opacity(isLeftEdgeHovered ? 1 : 0.4)
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isLeftEdgeHovered = hovering
                    }
                }
            }

            Spacer()

            // 右箭头
            if onNext != nil {
                Button {
                    onNext? { newItem in
                        withAnimation(.easeInOut(duration: 0.3)) {
                            mediaItem = newItem
                        }
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 60, height: 120)
                        .background(
                            RoundedRectangle(cornerRadius: 0, style: .continuous)
                                .fill(Color.black.opacity(isRightEdgeHovered ? 0.6 : 0.3))
                        )
                }
                .buttonStyle(.plain)
                .opacity(isRightEdgeHovered ? 1 : 0.4)
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isRightEdgeHovered = hovering
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
