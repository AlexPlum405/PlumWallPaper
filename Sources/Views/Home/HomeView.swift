import SwiftUI
import SwiftData

// MARK: - Artisan Monograph HomeView (Scheme C: Online Data Integration)
struct HomeView: View {
    @Binding var selectedWallpaper: Wallpaper?
    var onSwitchToWallpaperTab: (() -> Void)? = nil
    var onSwitchToMediaTab: (() -> Void)? = nil

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Wallpaper.importDate, order: .reverse) private var savedWallpapers: [Wallpaper]
    @StateObject var viewModel = HomeFeedViewModel()
    @State var currentHeroIndex = 0
    @State private var timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()
    @State private var isApplying = false
    @State private var isHeroDownloading = false
    @State private var isHeroFavoriteUpdating = false
    @State var currentDetailIndex: Int = 0
    @State var detailWallpaper: Wallpaper?
    @State private var isHeroLeftHovered = false
    @State private var isHeroRightHovered = false
    @State private var toast: ToastConfig?

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
                preheatHomeVideos()
            }
        }
        .onChange(of: viewModel.heroItems) { _, _ in
            preheatHomeVideos()
        }
        .onChange(of: viewModel.popularMotions) { _, _ in
            preheatHomeVideos()
        }
        .onChange(of: currentHeroIndex) { _, _ in
            preheatHeroVideos()
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
        .sheet(item: $detailWallpaper) { wallpaper in
            WallpaperDetailView(
                wallpaper: wallpaper,
                onPrevious: { current, callback in
                    let newWallpaper = getNavigateWallpaper(current: current, direction: -1)
                    callback(newWallpaper)
                },
                onNext: { current, callback in
                    let newWallpaper = getNavigateWallpaper(current: current, direction: 1)
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
        .toast($toast)
    }

    private func preheatHomeVideos() {
        preheatHeroVideos()
        let motionURLs = viewModel.popularMotions.compactMap(previewVideoURL(for:))
        VideoPreloader.shared.preload(urls: motionURLs, limit: 6)
    }

    private func preheatHeroVideos() {
        guard !viewModel.heroItems.isEmpty else { return }

        let count = viewModel.heroItems.count
        let indexes = [
            currentHeroIndex,
            (currentHeroIndex + 1) % count,
            (currentHeroIndex - 1 + count) % count
        ]

        let urls = indexes
            .map { viewModel.heroItems[$0] }
            .compactMap(bestHeroVideoURL(for:))

        VideoPreloader.shared.preload(urls: urls, limit: 3)
    }

    private func previewVideoURL(for item: MediaItem) -> URL? {
        item.previewVideoURL ?? item.fullVideoURL
    }

    // MARK: - Loading & Error States

    private func loadingView(size: CGSize) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Hero skeleton
                Rectangle()
                    .fill(LiquidGlassColors.surfaceBackground)
                    .frame(width: size.width, height: size.height)
                    .overlay(
                        VStack(spacing: 16) {
                            skeletonShimmer(width: 200, height: 20)
                            skeletonShimmer(width: 300, height: 32)
                            skeletonShimmer(width: 120, height: 44, cornerRadius: 22)
                        }
                    )

                // Stills section skeleton
                VStack(alignment: .leading, spacing: 32) {
                    VStack(alignment: .leading, spacing: 8) {
                        skeletonShimmer(width: 120, height: 10)
                        HStack(alignment: .firstTextBaseline) {
                            skeletonShimmer(width: 100, height: 28)
                            Spacer()
                        }
                    }.padding(.horizontal, mainPadding)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 32) {
                            ForEach(0..<4, id: \.self) { _ in
                                VStack(spacing: 0) {
                                    skeletonShimmer(width: 220, height: 140, cornerRadius: 0)
                                    VStack(alignment: .leading, spacing: 6) {
                                        skeletonShimmer(width: 160, height: 14)
                                        skeletonShimmer(width: 80, height: 10)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                }
                                .frame(width: 220)
                                .background(
                                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                                        .fill(LiquidGlassColors.surfaceBackground.opacity(0.6))
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                            }
                        }.padding(.horizontal, mainPadding)
                    }
                }
                .padding(.top, 100)

                // Motions section skeleton
                VStack(alignment: .leading, spacing: 32) {
                    VStack(alignment: .leading, spacing: 8) {
                        skeletonShimmer(width: 100, height: 10)
                        HStack(alignment: .firstTextBaseline) {
                            skeletonShimmer(width: 100, height: 28)
                            Spacer()
                        }
                    }.padding(.horizontal, mainPadding)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 32) {
                            ForEach(0..<4, id: \.self) { _ in
                                VStack(spacing: 0) {
                                    skeletonShimmer(width: 220, height: 140, cornerRadius: 0)
                                    VStack(alignment: .leading, spacing: 6) {
                                        skeletonShimmer(width: 140, height: 14)
                                        skeletonShimmer(width: 60, height: 10)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                }
                                .frame(width: 220)
                                .background(
                                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                                        .fill(LiquidGlassColors.surfaceBackground.opacity(0.6))
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                            }
                        }.padding(.horizontal, mainPadding)
                    }
                }
                .padding(.top, 100)
                .padding(.bottom, 160)
            }
        }
        .background(LiquidGlassColors.deepBackground)
    }

    private func skeletonShimmer(width: CGFloat, height: CGFloat, cornerRadius: CGFloat = 8) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(LiquidGlassColors.surfaceBackground)
            .frame(width: width, height: height)
            .opacity(0.6)
            .shimmering()
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
                    let item = viewModel.heroItems[currentHeroIndex]

                    // 只渲染当前视频。前后项通过 VideoPreloader 预热，避免 AppKit 视频层透出旧画面。
                    if let videoURL = bestHeroVideoURL(for: item) {
                        HeroVideoPlayer(url: videoURL, isActive: true)
                        .id(videoURL.absoluteString)
                        .frame(width: size.width, height: size.height)
                        .clipped()
                    } else {
                        AsyncImage(url: bestHeroImageURL(for: item)) { phase in
                            if let image = phase.image {
                                image.resizable().aspectRatio(contentMode: .fill)
                            } else { Color.black }
                        }
                        .frame(width: size.width, height: size.height)
                        .clipped()
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
                let item = viewModel.heroItems[currentHeroIndex]
                VStack(alignment: .leading, spacing: 14) {
                    Text(item.collectionTitle?.uppercased() ?? "FEATURED")
                        .font(.system(size: 9, weight: .black))
                        .kerning(4)
                        .foregroundStyle(LiquidGlassColors.primaryPink)

                    Text(item.title)
                        .font(.custom("Georgia", size: 44).bold())
                        .foregroundStyle(.white)

                    HStack(spacing: 10) {
                        artisanHeroMetaChip(text: "ORIGINAL", icon: "sparkles")
                        artisanHeroMetaChip(text: bestHeroResolutionLabel(for: item), icon: "square.resize")
                        artisanHeroMetaChip(text: item.sourceName.uppercased(), icon: "globe")
                    }

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
                        }
                        .buttonStyle(.plain)
                        .disabled(isApplying)

                        HStack(spacing: 12) {
                            heroActionIconButton(
                                icon: isHeroFavorite(item) ? "heart.fill" : "heart",
                                isActive: isHeroFavorite(item),
                                isBusy: isHeroFavoriteUpdating,
                                help: isHeroFavorite(item) ? "取消收藏" : "收藏"
                            ) {
                                Task { await toggleHeroFavorite(item) }
                            }

                            heroActionIconButton(
                                icon: "arrow.down.to.line.compact",
                                isActive: isHeroDownloaded(item),
                                isBusy: isHeroDownloading,
                                help: isHeroDownloaded(item) ? "已下载" : "下载原片"
                            ) {
                                Task { await downloadHero(item) }
                            }
                        }

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

    private func artisanHeroMetaChip(text: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .bold))
            Text(text)
                .font(.system(size: 10, weight: .black, design: .monospaced))
        }
        .foregroundStyle(.white.opacity(0.82))
        .padding(.horizontal, 11)
        .frame(height: 24)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.16), lineWidth: 0.5))
    }

    private func heroActionIconButton(
        icon: String,
        isActive: Bool,
        isBusy: Bool,
        help: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(isActive ? LiquidGlassColors.primaryPink.opacity(0.22) : Color.white.opacity(0.08))
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(
                        Circle()
                            .stroke(isActive ? LiquidGlassColors.primaryPink.opacity(0.5) : Color.white.opacity(0.14), lineWidth: 0.5)
                    )

                if isBusy {
                    CustomProgressView(tint: .white, scale: 0.65)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(isActive ? LiquidGlassColors.primaryPink : .white.opacity(0.86))
                }
            }
            .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
        .disabled(isBusy)
        .help(help)
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
                        let wallpaper = Wallpaper.from(remote: remoteWallpaper)
                        WallpaperCard(wallpaper: wallpaper, onTap: {
                            detailWallpaper = wallpaper
                        }, onDownload: {
                            Task {
                                await downloadRemoteFromCard(remoteWallpaper)
                            }
                        })
                        .onHover { hovering in
                            if hovering {
                                // hover 时预加载图片
                                let wallpaper = Wallpaper.from(remote: remoteWallpaper)
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
                        let wallpaper = Wallpaper.from(media: mediaItem)
                        WallpaperCard(wallpaper: wallpaper, onTap: {
                            detailWallpaper = wallpaper
                        }, onDownload: {
                            Task {
                                await downloadMediaFromCard(mediaItem)
                            }
                        })
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

    // Conversions moved to Wallpaper+Conversions.swift

    /// Navigate to previous/next wallpaper in detail view
    private func getNavigateWallpaper(current: Wallpaper? = nil, direction: Int) -> Wallpaper {
        let stillsWallpapers = viewModel.latestStills.map(Wallpaper.from)
        let motionsWallpapers = viewModel.popularMotions.map(Wallpaper.from)
        let activeWallpaper = current ?? detailWallpaper
        
        let allWallpapers: [Wallpaper]
        
        if let activeWallpaper,
           motionsWallpapers.contains(where: { $0.remoteId == activeWallpaper.remoteId || $0.name == activeWallpaper.name }) {
            allWallpapers = motionsWallpapers
        } else {
            allWallpapers = stillsWallpapers
        }

        guard !allWallpapers.isEmpty else {
            return activeWallpaper ?? Wallpaper(name: "Unknown", filePath: "", type: .image)
        }

        if let activeWallpaper,
           let currentIndex = allWallpapers.firstIndex(where: { $0.remoteId == activeWallpaper.remoteId || $0.name == activeWallpaper.name }) {
            let newIndex = (currentIndex + direction + allWallpapers.count) % allWallpapers.count
            return allWallpapers[newIndex]
        }

        return allWallpapers.first ?? Wallpaper(name: "Unknown", filePath: "", type: .image)
    }

    // MARK: - Hero Online Actions

    private func bestHeroVideoURL(for item: MediaItem) -> URL? {
        item.fullVideoURL ?? item.previewVideoURL
    }

    private func bestHeroImageURL(for item: MediaItem) -> URL {
        item.posterURL ?? item.thumbnailURL
    }

    private func bestHeroDownloadOption(for item: MediaItem) -> MediaDownloadOption? {
        item.downloadOptions.sorted { $0.qualityRank > $1.qualityRank }.first
    }

    private func bestHeroDownloadURL(for item: MediaItem) -> URL? {
        bestHeroDownloadOption(for: item)?.remoteURL
            ?? item.fullVideoURL
            ?? item.previewVideoURL
    }

    private func bestHeroResolutionLabel(for item: MediaItem) -> String {
        if let option = bestHeroDownloadOption(for: item) {
            return option.resolutionText
        }
        return item.exactResolution ?? item.resolutionLabel
    }

    private func bestHeroQualityLabel(for item: MediaItem) -> String {
        bestHeroDownloadOption(for: item)?.label ?? bestHeroResolutionLabel(for: item)
    }

    private func isHeroFavorite(_ item: MediaItem) -> Bool {
        savedWallpapers.contains { $0.remoteId == item.id && $0.isFavorite }
    }

    private func isHeroDownloaded(_ item: MediaItem) -> Bool {
        savedWallpapers.contains { wallpaper in
            wallpaper.remoteId == item.id
                && wallpaper.source == .downloaded
                && !isRemotePath(wallpaper.filePath)
                && FileManager.default.fileExists(atPath: wallpaper.filePath)
        }
    }

    private func toggleHeroFavorite(_ item: MediaItem) async {
        guard !isHeroFavoriteUpdating else { return }
        isHeroFavoriteUpdating = true
        defer { isHeroFavoriteUpdating = false }

        do {
            if let existing = try fetchSavedHeroWallpaper(remoteID: item.id) {
                if existing.isFavorite && existing.source == .online {
                    modelContext.delete(existing)
                    toast = ToastConfig(message: "已取消收藏", type: .info)
                } else {
                    existing.isFavorite.toggle()
                    toast = ToastConfig(message: existing.isFavorite ? "已加入收藏" : "已取消收藏", type: .success)
                }
            } else {
                let wallpaper = makeOnlineHeroWallpaper(from: item)
                modelContext.insert(wallpaper)
                toast = ToastConfig(message: "已加入收藏", type: .success)
            }

            try modelContext.save()
            SlideshowScheduler.shared.rebuildPlaylist()
        } catch {
            toast = ToastConfig(message: "收藏失败: \(error.localizedDescription)", type: .error)
        }
    }

    private func downloadHero(_ item: MediaItem) async {
        guard !isHeroDownloading else { return }

        if let existing = DownloadManager.shared.isAlreadyDownloaded(remoteId: item.id, context: modelContext) {
            if existing.isFavorite {
                toast = ToastConfig(message: "这张壁纸已在本地库中", type: .info)
            } else {
                toast = ToastConfig(message: "下载完成，已在本地库中", type: .info)
            }
            return
        }

        isHeroDownloading = true
        defer { isHeroDownloading = false }

        do {
            _ = try await downloadHeroIfNeeded(item)
            SlideshowScheduler.shared.rebuildPlaylist()
            toast = ToastConfig(message: "下载完成，已加入本地库", type: .success)
        } catch {
            toast = ToastConfig(message: "下载失败: \(error.localizedDescription)", type: .error)
        }
    }

    private func downloadHeroIfNeeded(_ item: MediaItem) async throws -> Wallpaper {
        if let existing = DownloadManager.shared.isAlreadyDownloaded(remoteId: item.id, context: modelContext) {
            return existing
        }

        guard let downloadURL = bestHeroDownloadURL(for: item) else {
            throw HomeHeroActionError.missingDownloadURL
        }

        return try await DownloadManager.shared.downloadWallpaper(
            item: .media(item),
            quality: bestHeroQualityLabel(for: item),
            downloadURL: downloadURL,
            context: modelContext
        )
    }

    private func downloadRemoteFromCard(_ wallpaper: RemoteWallpaper) async {
        guard let url = wallpaper.fullImageURL else {
            toast = ToastConfig(message: "缺少可下载的原图地址", type: .warning)
            return
        }

        if DownloadManager.shared.isAlreadyDownloaded(remoteId: wallpaper.id, context: modelContext) != nil {
            toast = ToastConfig(message: "这张壁纸已在本地库中", type: .info)
            return
        }

        do {
            _ = try await DownloadManager.shared.downloadWallpaper(
                item: .remote(wallpaper),
                quality: wallpaper.resolution,
                downloadURL: url,
                context: modelContext
            )
            SlideshowScheduler.shared.rebuildPlaylist()
            toast = ToastConfig(message: "下载完成，已加入本地库", type: .success)
        } catch {
            toast = ToastConfig(message: "下载失败: \(error.localizedDescription)", type: .error)
        }
    }

    private func downloadMediaFromCard(_ item: MediaItem) async {
        if DownloadManager.shared.isAlreadyDownloaded(remoteId: item.id, context: modelContext) != nil {
            toast = ToastConfig(message: "这张壁纸已在本地库中", type: .info)
            return
        }

        guard let downloadURL = bestHeroDownloadURL(for: item) else {
            toast = ToastConfig(message: "缺少可下载的原片地址", type: .warning)
            return
        }

        do {
            _ = try await DownloadManager.shared.downloadWallpaper(
                item: .media(item),
                quality: bestHeroQualityLabel(for: item),
                downloadURL: downloadURL,
                context: modelContext
            )
            SlideshowScheduler.shared.rebuildPlaylist()
            toast = ToastConfig(message: "下载完成，已加入本地库", type: .success)
        } catch {
            toast = ToastConfig(message: "下载失败: \(error.localizedDescription)", type: .error)
        }
    }

    private func fetchSavedHeroWallpaper(remoteID: String) throws -> Wallpaper? {
        let descriptor = FetchDescriptor<Wallpaper>(
            predicate: #Predicate { wallpaper in
                wallpaper.remoteId == remoteID
            },
            sortBy: [SortDescriptor(\.importDate, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).first
    }

    private func makeOnlineHeroWallpaper(from item: MediaItem) -> Wallpaper {
        let remoteSource: RemoteSourceType = item.sourceName.lowercased() == "steam workshop" ? .steamWorkshop : .motionBG
        let contentURL = bestHeroDownloadURL(for: item)?.absoluteString ?? ""
        let posterURL = bestHeroImageURL(for: item).absoluteString

        return Wallpaper(
            name: item.title,
            filePath: contentURL,
            type: .video,
            resolution: bestHeroResolutionLabel(for: item),
            fileSize: item.fileSize ?? 0,
            duration: item.durationSeconds,
            hasAudio: item.hasAudioTrack ?? false,
            thumbnailPath: posterURL,
            isFavorite: true,
            source: .online,
            remoteId: item.id,
            remoteSource: remoteSource,
            downloadQuality: item.fullVideoURL?.absoluteString,
            remoteMetadata: RemoteMetadata(
                author: item.authorName,
                views: item.viewCount,
                favorites: item.favoriteCount,
                uploadDate: item.createdAt,
                originalURL: item.pageURL.absoluteString
            )
        )
    }

    private func isRemotePath(_ path: String) -> Bool {
        guard let url = URL(string: path), let scheme = url.scheme?.lowercased() else {
            return false
        }
        return scheme == "http" || scheme == "https"
    }

    // MARK: - Hero 壁纸设置

    private func applyCurrentHeroAsWallpaper() async {
        guard !isApplying, !viewModel.heroItems.isEmpty else { return }

        let currentItem = viewModel.heroItems[currentHeroIndex]

        isApplying = true
        defer { isApplying = false }

        do {
            NSLog("[HomeView] 开始设置壁纸: \(currentItem.title)")

            let wallpaper = try await downloadHeroIfNeeded(currentItem)
            try await applyDownloadedWallpaper(wallpaper)
            SlideshowScheduler.shared.rebuildPlaylist()
            toast = ToastConfig(message: "已下载并应用最高质量壁纸", type: .success)
        } catch {
            NSLog("[HomeView] ❌ 设置壁纸失败: \(error.localizedDescription)")
            toast = ToastConfig(message: "设置失败: \(error.localizedDescription)", type: .error)
        }
    }

    private func applyDownloadedWallpaper(_ wallpaper: Wallpaper) async throws {
        let url = URL(fileURLWithPath: wallpaper.filePath)
        switch wallpaper.type {
        case .video:
            try await RenderPipeline.shared.setWallpaper(url: url, wallpaperId: wallpaper.id)
        case .image, .heic:
            RenderPipeline.shared.cleanup()
            try WallpaperSetter.shared.setWallpaper(imageURL: url)
        }

        var mapping: [String: UUID] = [:]
        for screen in DisplayManager.shared.availableScreens {
            mapping[screen.id] = wallpaper.id
        }
        RestoreManager.shared.saveSession(mapping: mapping)
        SlideshowScheduler.shared.onWallpaperChanged(wallpaper.id)
    }
}

private enum HomeHeroActionError: LocalizedError {
    case missingDownloadURL

    var errorDescription: String? {
        switch self {
        case .missingDownloadURL:
            return "缺少可下载的原片地址"
        }
    }
}

// MARK: - Shimmer Effect
private struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [.clear, .white.opacity(0.08), .clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .rotationEffect(.degrees(30))
                .offset(x: phase * 300)
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

private extension View {
    func shimmering() -> some View {
        modifier(ShimmerModifier())
    }
}
