import SwiftUI

// MARK: - Artisan Monograph HomeView (Scheme C: Online Data Integration)
struct HomeView: View {
    @Binding var selectedWallpaper: Wallpaper?
    var onSwitchToWallpaperTab: (() -> Void)? = nil
    var onSwitchToMediaTab: (() -> Void)? = nil

    @StateObject var viewModel = HomeFeedViewModel()
    @State var currentHeroIndex = 0
    @State private var timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()
    @State private var isApplying = false
    @State var currentDetailIndex: Int = 0
    @State var detailWallpaper: Wallpaper?
    @State var detailMediaItem: MediaItem?  // 用于显示在线媒体详情
    @State private var isHeroLeftHovered = false
    @State private var isHeroRightHovered = false
    @State private var showVideoAlert = false
    @State private var videoAlertMessage = ""

    private let mainPadding: CGFloat = 88

    var body: some View {
        GeometryReader { windowGeo in
            ZStack(alignment: .top) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        if viewModel.isLoading && viewModel.latestStills.isEmpty {
                            loadingView(size: windowGeo.size)
                        } else if let errorMessage = viewModel.errorMessage, viewModel.latestStills.isEmpty {
                            errorView(message: errorMessage, size: windowGeo.size)
                        } else if viewModel.heroItems.isEmpty && viewModel.latestStills.isEmpty && viewModel.popularMotions.isEmpty {
                            emptyStateView(size: windowGeo.size)
                        } else {
                            // Hero 轮播（如果有数据）
                            if !viewModel.heroItems.isEmpty {
                                artisanFullscreenHero(size: windowGeo.size)
                            }

                            VStack(alignment: .leading, spacing: 100) {
                                if !viewModel.latestStills.isEmpty {
                                    artisanStillsSection()
                                }
                                if !viewModel.popularMotions.isEmpty {
                                    artisanMotionsSection()
                                }
                            }
                            .padding(.top, viewModel.heroItems.isEmpty ? 100 : 100)
                            .padding(.bottom, 160)
                            .background(LiquidGlassColors.deepBackground)
                        }
                    }
                }
                .refreshable {
                    await viewModel.refresh()
                }
            }
        }
        .onAppear {
            NSLog("[HomeView] .onAppear 被调用")
            // 强制在 onAppear 时加载数据
            Task {
                NSLog("[HomeView] 开始加载初始数据")
                await viewModel.loadInitialData()
            }
        }
        .onReceive(timer) { _ in
            if !isApplying && !viewModel.heroItems.isEmpty {
                withAnimation(.galleryEase) {
                    currentHeroIndex = (currentHeroIndex + 1) % viewModel.heroItems.count
                }
            }
        }
        .onKeyPress(.leftArrow) {
            guard !viewModel.heroItems.isEmpty else { return .ignored }
            withAnimation(.gallerySpring) {
                currentHeroIndex = (currentHeroIndex - 1 + viewModel.heroItems.count) % viewModel.heroItems.count
            }
            return .handled
        }
        .onKeyPress(.rightArrow) {
            guard !viewModel.heroItems.isEmpty else { return .ignored }
            withAnimation(.gallerySpring) {
                currentHeroIndex = (currentHeroIndex + 1) % viewModel.heroItems.count
            }
            return .handled
        }
        .alert("提示", isPresented: $showVideoAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(videoAlertMessage)
        }
        .sheet(item: $detailWallpaper) { wallpaper in
            WallpaperDetailView(
                wallpaper: wallpaper,
                onPrevious: { callback in
                    let newWallpaper = getNavigateWallpaper(direction: -1)
                    detailWallpaper = newWallpaper
                    callback(newWallpaper)
                },
                onNext: { callback in
                    let newWallpaper = getNavigateWallpaper(direction: 1)
                    detailWallpaper = newWallpaper
                    callback(newWallpaper)
                },
                onFavorite: { updatedWallpaper in
                    NSLog("[HomeView] 收藏状态变更: \(updatedWallpaper.name) -> \(updatedWallpaper.isFavorite)")
                },
                onDownload: { downloadedWallpaper in
                    NSLog("[HomeView] 壁纸已下载: \(downloadedWallpaper.name)")
                }
            )
        }
        .sheet(item: $detailMediaItem) { mediaItem in
            MediaDetailView(
                mediaItem: mediaItem,
                onPrevious: { callback in
                    let newMediaItem = getNavigateMediaItem(direction: -1)
                    detailMediaItem = newMediaItem
                    callback(newMediaItem)
                },
                onNext: { callback in
                    let newMediaItem = getNavigateMediaItem(direction: 1)
                    detailMediaItem = newMediaItem
                    callback(newMediaItem)
                }
            )
        }
    }

    // MARK: - Loading & Error States

    private func loadingView(size: CGSize) -> some View {
        ZStack {
            LiquidGlassColors.deepBackground
            VStack(spacing: 24) {
                CustomProgressView(tint: LiquidGlassColors.primaryPink, scale: 1.2)
                Text("Loading Gallery...")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(LiquidGlassColors.textSecondary)
            }
        }
        .frame(height: size.height)
    }

    private func errorView(message: String, size: CGSize) -> some View {
        ZStack {
            LiquidGlassColors.deepBackground
            VStack(spacing: 24) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 48))
                    .foregroundStyle(LiquidGlassColors.primaryPink)
                Text(message)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(LiquidGlassColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                Button("Retry") {
                    Task { await viewModel.loadInitialData() }
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 32)
                .frame(height: 44)
                .background(Capsule().fill(LiquidGlassColors.primaryPink))
                .artisanShadow(color: LiquidGlassColors.primaryPink.opacity(0.3), radius: 15)
            }
        }
        .frame(height: size.height)
    }

    private func emptyStateView(size: CGSize) -> some View {
        ZStack {
            LiquidGlassColors.deepBackground
            VStack(spacing: 24) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 48))
                    .foregroundStyle(LiquidGlassColors.textQuaternary)
                Text("暂无内容")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(LiquidGlassColors.textSecondary)
                Text("下拉刷新试试")
                    .font(.system(size: 13))
                    .foregroundStyle(LiquidGlassColors.textQuaternary)
                Button("刷新") {
                    Task { await viewModel.refresh() }
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 32)
                .frame(height: 44)
                .background(Capsule().fill(LiquidGlassColors.primaryPink))
                .artisanShadow(color: LiquidGlassColors.primaryPink.opacity(0.3), radius: 15)
            }
        }
        .frame(height: size.height)
    }

    // MARK: - Hero Section

    private func artisanFullscreenHero(size: CGSize) -> some View {
        ZStack(alignment: .bottomLeading) {
            // 视频层 - 只预加载当前和前后各1个视频
            ZStack {
                if !viewModel.heroItems.isEmpty {
                    let itemsArray = Array(viewModel.heroItems.enumerated())
                    ForEach(itemsArray, id: \.element.id) { index, item in
                        // 只渲染当前视频和前后各1个视频
                        let shouldRender = abs(index - currentHeroIndex) <= 1 ||
                                         (currentHeroIndex == 0 && index == viewModel.heroItems.count - 1) ||
                                         (currentHeroIndex == viewModel.heroItems.count - 1 && index == 0)

                        if shouldRender {
                            // 使用 2K 视频（previewVideoURL 1920x1080），回退到 4K，最后回退到图片
                            if let videoURL = item.previewVideoURL ?? item.fullVideoURL {
                                VideoPlayer(
                                    url: videoURL,
                                    posterURL: item.thumbnailURL,
                                    isActive: index == currentHeroIndex
                                )
                                .opacity(index == currentHeroIndex ? 1 : 0)
                                .zIndex(index == currentHeroIndex ? 1 : 0)
                                .allowsHitTesting(index == currentHeroIndex)
                            } else {
                                AsyncImage(url: item.thumbnailURL) { phase in
                                    if let image = phase.image {
                                        image.resizable().aspectRatio(contentMode: .fill)
                                    } else { Color.black }
                                }
                                .opacity(index == currentHeroIndex ? 1 : 0)
                                .zIndex(index == currentHeroIndex ? 1 : 0)
                            }
                        }
                    }
                }
            }
            .frame(width: size.width, height: size.height).clipped()
            .animation(.easeInOut(duration: 0.8), value: currentHeroIndex)

            LinearGradient(
                colors: [.clear, LiquidGlassColors.deepBackground.opacity(0.8), LiquidGlassColors.deepBackground],
                startPoint: .init(x: 0.5, y: 0.7),
                endPoint: .bottom
            ).frame(height: 300)

            if !viewModel.heroItems.isEmpty {
                VStack(alignment: .leading, spacing: 14) {
                    Text(viewModel.heroItems[currentHeroIndex].collectionTitle?.uppercased() ?? "FEATURED")
                        .font(.system(size: 9, weight: .black))
                        .kerning(4)
                        .foregroundStyle(LiquidGlassColors.primaryPink)

                    Text(viewModel.heroItems[currentHeroIndex].title)
                        .font(.custom("Georgia", size: 44).bold())
                        .foregroundStyle(.white)

                    HStack(spacing: 24) {
                        Button(action: {
                            Task {
                                await applyCurrentHeroAsWallpaper()
                            }
                        }) {
                            HStack(spacing: 12) {
                                if isApplying {
                                    CustomProgressView(tint: .white, scale: 0.8)
                                } else {
                                    Image(systemName: "macwindow.on.rectangle").font(.system(size: 14))
                                    Text("设为壁纸").font(.system(size: 13, weight: .bold)).kerning(1.5)
                                }
                            }
                            .padding(.horizontal, 32).frame(height: 44)
                            .background(Capsule().fill(LiquidGlassColors.primaryPink))
                            .artisanShadow(color: LiquidGlassColors.primaryPink.opacity(0.3), radius: 15)
                        }.buttonStyle(.plain)

                        HStack(spacing: 8) {
                            ForEach(0..<viewModel.heroItems.count, id: \.self) { index in
                                Circle()
                                    .fill(index == currentHeroIndex ? Color.white : Color.white.opacity(0.2))
                                    .frame(width: 5, height: 5)
                            }
                        }
                    }
                }
                .padding(.leading, mainPadding).padding(.bottom, 100)
            }

            // Navigation arrows
            HStack {
                artisanHeroNavButton(isLeft: true)
                Spacer()
                artisanHeroNavButton(isLeft: false)
            }
        }
        .frame(height: size.height)
    }

    private func artisanHeroNavButton(isLeft: Bool) -> some View {
        let isHovered = isLeft ? isHeroLeftHovered : isHeroRightHovered

        return Button(action: {
            guard !viewModel.heroItems.isEmpty else { return }
            withAnimation(.gallerySpring) {
                if isLeft {
                    currentHeroIndex = (currentHeroIndex - 1 + viewModel.heroItems.count) % viewModel.heroItems.count
                } else {
                    currentHeroIndex = (currentHeroIndex + 1) % viewModel.heroItems.count
                }
            }
        }) {
            ZStack {
                Rectangle()
                    .fill(Color.white.opacity(0.001))
                    .frame(width: 100, height: .infinity)

                Image(systemName: isLeft ? "chevron.left" : "chevron.right")
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(.white.opacity(isHovered ? 0.9 : 0.4))  // 默认 0.4 可见
                    .offset(x: isLeft ? 40 : -40)
            }
        }
        .buttonStyle(.plain)
        .onHover { isLeft ? (isHeroLeftHovered = $0) : (isHeroRightHovered = $0) }
    }

    // MARK: - Latest Stills Section

    private func artisanStillsSection() -> some View {
        VStack(alignment: .leading, spacing: 32) {
            VStack(alignment: .leading, spacing: 8) {
                Text("NEW ACQUISITIONS")
                    .font(.system(size: 9, weight: .black))
                    .kerning(3)
                    .foregroundStyle(LiquidGlassColors.primaryPink)

                HStack(alignment: .firstTextBaseline) {
                    Text("最新画作")
                        .font(.custom("Georgia", size: 28).bold())
                    Rectangle()
                        .fill(LiquidGlassColors.glassBorder.opacity(0.2))
                        .frame(width: 80, height: 0.5)
                        .padding(.leading, 16)
                    Spacer()
                    Button("VIEW ALL") {
                        onSwitchToWallpaperTab?()
                    }
                        .font(.system(size: 10, weight: .black))
                        .kerning(2)
                        .foregroundStyle(LiquidGlassColors.textQuaternary)
                        .buttonStyle(.plain)
                }
            }.padding(.horizontal, mainPadding)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 32) {
                    ForEach(viewModel.latestStills) { remoteWallpaper in
                        WallpaperCard(wallpaper: convertToWallpaper(remoteWallpaper)) {
                            detailWallpaper = convertToWallpaper(remoteWallpaper)
                        }
                        .onHover { hovering in
                            if hovering {
                                // hover 时预加载图片
                                let wallpaper = convertToWallpaper(remoteWallpaper)
                                if let url = URL(string: wallpaper.filePath) {
                                    // 预加载图片到缓存
                                    URLSession.shared.dataTask(with: url).resume()
                                }
                            }
                        }
                    }
                }.padding(.horizontal, mainPadding).padding(.bottom, 20)
            }
        }
    }

    // MARK: - Popular Motions Section

    private func artisanMotionsSection() -> some View {
        VStack(alignment: .leading, spacing: 32) {
            VStack(alignment: .leading, spacing: 8) {
                Text("KINETIC ART")
                    .font(.system(size: 9, weight: .black))
                    .kerning(3)
                    .foregroundStyle(LiquidGlassColors.primaryPink)

                HStack(alignment: .firstTextBaseline) {
                    Text("热门动态")
                        .font(.custom("Georgia", size: 28).bold())
                    Rectangle()
                        .fill(LiquidGlassColors.glassBorder.opacity(0.2))
                        .frame(width: 80, height: 0.5)
                        .padding(.leading, 16)
                    Spacer()
                    Button("VIEW ALL") {
                        onSwitchToMediaTab?()
                    }
                        .font(.system(size: 10, weight: .black))
                        .kerning(2)
                        .foregroundStyle(LiquidGlassColors.textQuaternary)
                        .buttonStyle(.plain)
                }
            }.padding(.horizontal, mainPadding)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 32) {
                    ForEach(viewModel.popularMotions) { mediaItem in
                        WallpaperCard(wallpaper: convertToWallpaper(mediaItem)) {
                            detailMediaItem = mediaItem  // 使用 MediaDetailView
                        }
                        .onHover { hovering in
                            if hovering {
                                // hover 时预加载视频
                                if let videoURL = mediaItem.previewVideoURL ?? mediaItem.fullVideoURL {
                                    VideoPreloader.shared.preload(url: videoURL)
                                }
                            }
                        }
                    }
                }.padding(.horizontal, mainPadding).padding(.bottom, 20)
            }
        }
    }

    // MARK: - Data Conversion Helpers

    /// Convert RemoteWallpaper to temporary Wallpaper for display
    private func convertToWallpaper(_ remote: RemoteWallpaper) -> Wallpaper {
        let wallpaper = Wallpaper(
            name: remote.id,
            filePath: remote.fullImageURL?.absoluteString ?? "",
            type: .image,
            resolution: remote.resolution,
            fileSize: remote.fileSize,
            thumbnailPath: remote.thumbURL?.absoluteString,
            source: .downloaded,
            remoteId: remote.id,
            remoteSource: .wallhaven,
            remoteMetadata: RemoteMetadata(
                author: nil,
                views: remote.views,
                favorites: remote.favorites,
                uploadDate: remote.uploadedAt,
                originalURL: remote.url
            )
        )
        return wallpaper
    }

    /// Convert MediaItem to temporary Wallpaper for display
    private func convertToWallpaper(_ media: MediaItem) -> Wallpaper {
        let remoteSource: RemoteSourceType = {
            switch media.sourceName.lowercased() {
            case "motionbg": return .motionBG
            case "steam workshop": return .steamWorkshop
            default: return .motionBG
            }
        }()

        let wallpaper = Wallpaper(
            name: media.title,
            filePath: media.fullVideoURL?.absoluteString ?? media.previewVideoURL?.absoluteString ?? "",
            type: .video,
            resolution: media.exactResolution ?? media.resolutionLabel,
            fileSize: media.fileSize ?? 0,
            duration: media.durationSeconds,
            thumbnailPath: media.thumbnailURL.absoluteString,
            source: .downloaded,
            remoteId: media.id,
            remoteSource: remoteSource,
            remoteMetadata: RemoteMetadata(
                author: media.authorName,
                views: media.viewCount,
                favorites: media.favoriteCount,
                uploadDate: media.createdAt,
                originalURL: media.pageURL.absoluteString
            )
        )
        return wallpaper
    }

    /// Navigate to previous/next wallpaper in detail view
    private func getNavigateWallpaper(direction: Int) -> Wallpaper {
        // Combine all items for navigation
        let allWallpapers: [Wallpaper] = viewModel.latestStills.map(convertToWallpaper)

        guard !allWallpapers.isEmpty else {
            return detailWallpaper ?? Wallpaper(name: "Unknown", filePath: "", type: .image)
        }

        if let current = detailWallpaper,
           let currentIndex = allWallpapers.firstIndex(where: { $0.remoteId == current.remoteId }) {
            let newIndex = (currentIndex + direction + allWallpapers.count) % allWallpapers.count
            return allWallpapers[newIndex]
        }

        return allWallpapers.first ?? Wallpaper(name: "Unknown", filePath: "", type: .image)
    }

    private func getNavigateMediaItem(direction: Int) -> MediaItem {
        let allMediaItems = viewModel.popularMotions

        guard !allMediaItems.isEmpty else {
            return detailMediaItem ?? MediaItem(
                slug: "unknown",
                title: "Unknown",
                pageURL: URL(string: "https://example.com")!,
                thumbnailURL: URL(string: "https://example.com")!,
                resolutionLabel: "Unknown",
                collectionTitle: nil,
                summary: nil,
                previewVideoURL: nil,
                fullVideoURL: nil,
                posterURL: nil,
                tags: [],
                exactResolution: nil,
                durationSeconds: nil,
                downloadOptions: [],
                sourceName: "Unknown",
                isAnimatedImage: false
            )
        }

        if let current = detailMediaItem,
           let currentIndex = allMediaItems.firstIndex(where: { $0.id == current.id }) {
            let newIndex = (currentIndex + direction + allMediaItems.count) % allMediaItems.count
            return allMediaItems[newIndex]
        }

        return allMediaItems[0]
    }

    // MARK: - Hero 壁纸设置

    private func applyCurrentHeroAsWallpaper() async {
        guard !viewModel.heroItems.isEmpty else { return }

        let currentItem = viewModel.heroItems[currentHeroIndex]

        // 视频壁纸暂不支持设为 macOS 桌面
        if currentItem.fullVideoURL != nil || currentItem.previewVideoURL != nil {
            if currentItem.posterURL == nil {
                videoAlertMessage = "此为视频壁纸，暂不支持设为 macOS 桌面。未来版本将支持视频壁纸。"
                showVideoAlert = true
                return
            }
        }

        isApplying = true
        defer { isApplying = false }

        do {
            NSLog("[HomeView] 开始设置壁纸: \(currentItem.title)")

            // 1. 下载图片（优先使用 posterURL 高清静态帧）
            let imageURL = currentItem.posterURL ?? currentItem.thumbnailURL
            let tempDir = FileManager.default.temporaryDirectory
            let filename = "\(currentItem.slug).jpg"
            let localURL = tempDir.appendingPathComponent(filename)

            // 检查是否已下载
            if !FileManager.default.fileExists(atPath: localURL.path) {
                NSLog("[HomeView] 下载图片: \(imageURL.absoluteString)")

                let (data, _) = try await URLSession.shared.data(from: imageURL)
                try data.write(to: localURL)

                NSLog("[HomeView] ✅ 下载完成: \(localURL.path)")
            } else {
                NSLog("[HomeView] 使用缓存文件: \(localURL.path)")
            }

            // 2. 设置为壁纸
            try await MainActor.run {
                try WallpaperSetter.shared.setWallpaper(imageURL: localURL)
            }

            NSLog("[HomeView] ✅ 壁纸设置成功")

            // 3. 显示成功提示（可选）
            // TODO: 添加 Toast 通知

        } catch {
            NSLog("[HomeView] ❌ 设置壁纸失败: \(error.localizedDescription)")
            // TODO: 显示错误提示
        }
    }
}

