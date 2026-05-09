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
    @State var detailItem: WallpaperPreviewItem?
    @State private var isHeroLeftHovered = false
    @State private var isHeroRightHovered = false
    @State private var readyHeroVideoURL: URL?
    @State private var toast: ToastConfig?
    @State private var isChoosingApplyScreen = false

    private let mainPadding: CGFloat = 72

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

                            VStack(alignment: .leading, spacing: 80) {
                                if !viewModel.latestStills.isEmpty {
                                    artisanStillsSection()
                                }
                                if !viewModel.popularMotions.isEmpty {
                                    artisanMotionsSection()
                                }
                            }
                            .padding(.top, viewModel.heroItems.isEmpty ? 120 : 80)
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
            isApplying = false
            isHeroDownloading = false
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
        .sheet(item: $detailItem) { item in
            WallpaperDetailView(
                wallpaper: item.makeWallpaper(),
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
        .confirmationDialog("选择要应用的屏幕", isPresented: $isChoosingApplyScreen, titleVisibility: .visible) {
            ForEach(DisplayManager.shared.availableScreens) { screen in
                Button("\(screen.name) · \(screen.resolution)") {
                    Task { await applyCurrentHeroAsWallpaper(targetScreenId: screen.id) }
                }
            }
        }
        .toast($toast)
    }

    private func preheatHomeVideos() {
        preheatHeroVideos()
        PreviewResourcePipeline.shared.preloadPreviewVideos(for: viewModel.popularMotions, limit: 6)
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
            .compactMap(PreviewResourcePipeline.shared.previewVideoURL(for:))

        PreviewResourcePipeline.shared.preloadVideos(urls: urls, limit: 3)
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
        let heroHeight = max(520, size.height * 0.68)

        return ZStack(alignment: .bottomLeading) {
            // 视频层 - 只预加载当前和前后各1个视频
            ZStack {
                if !viewModel.heroItems.isEmpty {
                    let item = viewModel.heroItems[currentHeroIndex]

                    // 只渲染当前视频。前后项通过 VideoPreloader 预热，避免 AppKit 视频层透出旧画面。
                    if let videoURL = bestHeroVideoURL(for: item) {
                        RemoteThumbnailImage(urls: [bestHeroImageURL(for: item)], contentMode: .fill)
                            .frame(width: size.width, height: heroHeight)
                            .clipped()

                        HeroVideoPlayer(url: videoURL, isActive: true) { isReady in
                            if isReady {
                                readyHeroVideoURL = videoURL
                            } else if readyHeroVideoURL == videoURL {
                                readyHeroVideoURL = nil
                            }
                        }
                        .id(videoURL.absoluteString)
                        .frame(width: size.width, height: heroHeight)
                        .clipped()
                        .opacity(readyHeroVideoURL == videoURL ? 1 : 0)
                        .animation(.easeInOut(duration: 0.18), value: readyHeroVideoURL)
                    } else {
                        RemoteThumbnailImage(urls: [bestHeroImageURL(for: item)], contentMode: .fill)
                        .frame(width: size.width, height: heroHeight)
                        .clipped()
                    }
                }
            }
            .frame(width: size.width, height: heroHeight).clipped()
            .animation(.easeInOut(duration: 0.8), value: currentHeroIndex)

            LinearGradient(
                colors: [.clear, LiquidGlassColors.deepBackground.opacity(0.82), LiquidGlassColors.deepBackground],
                startPoint: .init(x: 0.5, y: 0.55),
                endPoint: .bottom
            ).frame(height: 320)

            if !viewModel.heroItems.isEmpty {
                let item = viewModel.heroItems[currentHeroIndex]
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 8) {
                        Text(item.collectionTitle?.uppercased() ?? "TODAY'S PICK")
                            .font(.system(size: 10, weight: .bold))
                            .kerning(3)
                            .foregroundStyle(LiquidGlassColors.primaryPink)
                        Circle()
                            .fill(LiquidGlassColors.primaryPink.opacity(0.7))
                            .frame(width: 3, height: 3)
                        Text(item.sourceName.uppercased())
                            .font(.system(size: 10, weight: .semibold))
                            .kerning(2)
                            .foregroundStyle(LiquidGlassColors.textSecondary)
                    }

                    Text(item.title)
                        .font(.system(size: 42, weight: .bold, design: .default))
                        .foregroundStyle(.white)
                        .lineLimit(2)

                    HStack(spacing: 10) {
                        artisanHeroMetaChip(text: bestHeroResolutionLabel(for: item), icon: "rectangle.expand.vertical")
                        if let duration = item.durationSeconds {
                            artisanHeroMetaChip(text: formatHeroDuration(duration), icon: "clock")
                        }
                        if item.hasAudioTrack == true {
                            artisanHeroMetaChip(text: "AUDIO", icon: "waveform")
                        }
                        artisanHeroMetaChip(text: "ORIGINAL", icon: "sparkles")
                    }

                    HStack(spacing: 16) {
                        Button(action: {
                            Task {
                                await applyCurrentHeroAsWallpaper()
                            }
                        }) {
                            HStack(spacing: 10) {
                                if isApplying {
                                    CustomProgressView(tint: .white, scale: 0.8)
                                } else {
                                    Image(systemName: "macwindow.on.rectangle").font(.system(size: 13, weight: .bold))
                                    Text("设为壁纸").font(.system(size: 13, weight: .bold)).kerning(1.2)
                                }
                            }
                            .padding(.horizontal, 28).frame(height: 44)
                            .background(
                                Capsule().fill(
                                    LinearGradient(
                                        colors: [LiquidGlassColors.primaryPink, LiquidGlassColors.tertiaryBlue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                            )
                            .foregroundStyle(.black.opacity(0.85))
                            .artisanShadow(color: LiquidGlassColors.primaryPink.opacity(0.25), radius: 18)
                        }
                        .buttonStyle(.plain)
                        .disabled(isApplying)
                        .keyboardShortcut(.return, modifiers: [])

                        Button(action: { Task { await downloadHero(item) } }) {
                            HStack(spacing: 6) {
                                if isHeroDownloading {
                                    CustomProgressView(tint: LiquidGlassColors.textSecondary, scale: 0.55)
                                } else {
                                    Image(systemName: isHeroDownloaded(item) ? "checkmark" : "arrow.down.to.line.compact")
                                        .font(.system(size: 11, weight: .semibold))
                                }
                                Text(isHeroDownloaded(item) ? "已下载" : "下载原片")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundStyle(LiquidGlassColors.textSecondary)
                        }
                        .buttonStyle(.plain)
                        .disabled(isHeroDownloading)

                        heroActionIconButton(
                            icon: isHeroFavorite(item) ? "heart.fill" : "heart",
                            isActive: isHeroFavorite(item),
                            isBusy: isHeroFavoriteUpdating,
                            help: isHeroFavorite(item) ? "取消收藏" : "收藏"
                        ) {
                            Task { await toggleHeroFavorite(item) }
                        }

                        Spacer()

                        HStack(spacing: 6) {
                            ForEach(0..<viewModel.heroItems.count, id: \.self) { index in
                                Capsule()
                                    .fill(index == currentHeroIndex ? LiquidGlassColors.primaryPink : Color.white.opacity(0.18))
                                    .frame(width: index == currentHeroIndex ? 18 : 6, height: 4)
                                    .animation(.gallerySpring, value: currentHeroIndex)
                            }
                        }
                    }
                }
                .padding(.leading, mainPadding).padding(.trailing, mainPadding).padding(.bottom, 80)
                .zIndex(2)
            }

            // Navigation arrows
            HStack {
                artisanHeroNavButton(isLeft: true)
                Spacer()
                artisanHeroNavButton(isLeft: false)
            }
            .zIndex(1)
        }
        .frame(height: heroHeight)
    }

    private func formatHeroDuration(_ seconds: Double) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: seconds) ?? "0:00"
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
        VStack(alignment: .leading, spacing: 28) {
            VStack(alignment: .leading, spacing: 8) {
                Text("STATIC WALLPAPERS")
                    .font(.system(size: 10, weight: .bold))
                    .kerning(3)
                    .foregroundStyle(LiquidGlassColors.primaryPink)

                HStack(alignment: .firstTextBaseline) {
                    Text("最新静态壁纸")
                        .font(.system(size: 28, weight: .bold))
                    Text("适合快速浏览与直接应用")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(LiquidGlassColors.textSecondary)
                        .padding(.leading, 12)
                    Spacer()
                    Button("查看全部") {
                        onSwitchToWallpaperTab?()
                    }
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(LiquidGlassColors.textSecondary)
                        .buttonStyle(.plain)
                }
            }.padding(.horizontal, mainPadding)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 32) {
                    ForEach(viewModel.latestStills) { remoteWallpaper in
                        let item = WallpaperPreviewItem(remote: remoteWallpaper)
                        WallpaperCard(previewItem: item, onTap: {
                            detailItem = item
                        }, onDownload: {
                            Task {
                                await downloadRemoteFromCard(remoteWallpaper)
                            }
                        })
                        .onContinuousHover { phase in
                            switch phase {
                            case .active:
                                Task {
                                    try? await Task.sleep(nanoseconds: 400_000_000)
                                    await PreviewResourcePipeline.shared.prefetchFullResolution(for: item)
                                }
                            case .ended:
                                break
                            }
                        }
                    }
                }.padding(.horizontal, mainPadding).padding(.bottom, 20)
            }
        }
    }

    // MARK: - Popular Motions Section

    private func artisanMotionsSection() -> some View {
        VStack(alignment: .leading, spacing: 28) {
            VStack(alignment: .leading, spacing: 8) {
                Text("MOTION WALLPAPERS")
                    .font(.system(size: 10, weight: .bold))
                    .kerning(3)
                    .foregroundStyle(LiquidGlassColors.primaryPink)

                HStack(alignment: .firstTextBaseline) {
                    Text("热门动态壁纸")
                        .font(.system(size: 28, weight: .bold))
                    Text("关注时长、音频与分辨率")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(LiquidGlassColors.textSecondary)
                        .padding(.leading, 12)
                    Spacer()
                    Button("查看全部") {
                        onSwitchToMediaTab?()
                    }
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(LiquidGlassColors.textSecondary)
                        .buttonStyle(.plain)
                }
            }.padding(.horizontal, mainPadding)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 32) {
                    ForEach(viewModel.popularMotions) { mediaItem in
                        let item = WallpaperPreviewItem(media: mediaItem)
                        WallpaperCard(previewItem: item, onTap: {
                            detailItem = item
                        }, onDownload: {
                            Task {
                                await downloadMediaFromCard(mediaItem)
                            }
                        })
                        .onContinuousHover { phase in
                            switch phase {
                            case .active:
                                Task {
                                    try? await Task.sleep(nanoseconds: 400_000_000)
                                    await PreviewResourcePipeline.shared.prefetchFullResolution(for: mediaItem)
                                    PreviewResourcePipeline.shared.preloadVideo(for: mediaItem, preferFullResolution: true)
                                }
                            case .ended:
                                break
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
        let stillItems = viewModel.latestStills.map(WallpaperPreviewItem.init(remote:))
        let motionItems = viewModel.popularMotions.map(WallpaperPreviewItem.init(media:))
        let activeRemoteId = current?.remoteId ?? detailItem?.remoteId
        let activeTitle = current?.name ?? detailItem?.title
        
        let allItems: [WallpaperPreviewItem]
        
        if motionItems.contains(where: { $0.remoteId == activeRemoteId || $0.title == activeTitle }) {
            allItems = motionItems
        } else {
            allItems = stillItems
        }

        guard !allItems.isEmpty else {
            return current ?? detailItem?.makeWallpaper() ?? Wallpaper(name: "Unknown", filePath: "", type: .image)
        }

        if let currentIndex = allItems.firstIndex(where: { $0.remoteId == activeRemoteId || $0.title == activeTitle }) {
            let newIndex = (currentIndex + direction + allItems.count) % allItems.count
            return allItems[newIndex].makeWallpaper()
        }

        return allItems.first?.makeWallpaper() ?? Wallpaper(name: "Unknown", filePath: "", type: .image)
    }

    // MARK: - Hero Online Actions

    private func bestHeroVideoURL(for item: MediaItem) -> URL? {
        PreviewResourcePipeline.shared.previewVideoURL(for: item)
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
                NSLog("[HomeView] 创建在线收藏壁纸: \(wallpaper.name), type: \(wallpaper.type), source: \(wallpaper.source), isFavorite: \(wallpaper.isFavorite)")

                // 下载缩略图到本地
                if let remoteThumbnailURL = URL(string: wallpaper.thumbnailPath ?? ""),
                   remoteThumbnailURL.scheme?.hasPrefix("http") == true {
                    if let localThumbnail = await downloadThumbnailToLocal(from: remoteThumbnailURL) {
                        wallpaper.thumbnailPath = localThumbnail
                        NSLog("[HomeView] 缩略图已下载到本地: \(localThumbnail)")
                    } else {
                        NSLog("[HomeView] ⚠️ 缩略图下载失败，使用远程 URL")
                    }
                }

                modelContext.insert(wallpaper)
                NSLog("[HomeView] 壁纸已插入 modelContext")
                toast = ToastConfig(message: "已加入收藏", type: .success)
            }

            try modelContext.save()
            NSLog("[HomeView] ✅ modelContext 已保存")

            // 验证保存是否成功
            if let saved = try fetchSavedHeroWallpaper(remoteID: item.id) {
                NSLog("[HomeView] ✅ 验证成功，已保存壁纸: \(saved.name), isFavorite: \(saved.isFavorite), source: \(saved.source)")
            } else {
                NSLog("[HomeView] ❌ 验证失败，未找到保存的壁纸")
            }

            SlideshowScheduler.shared.rebuildPlaylist()
        } catch {
            toast = ToastConfig(message: "收藏失败: \(error.localizedDescription)", type: .error)
        }
    }

    private func downloadHero(_ item: MediaItem) async {
        NSLog("[HomeView] downloadHero 开始: \(item.title), isHeroDownloading=\(isHeroDownloading)")
        guard !isHeroDownloading else {
            NSLog("[HomeView] downloadHero 已有下载任务，跳过")
            return
        }

        if let existing = DownloadManager.shared.isAlreadyDownloaded(remoteId: item.id, context: modelContext) {
            NSLog("[HomeView] downloadHero 壁纸已存在: \(existing.name)")
            if existing.isFavorite {
                toast = ToastConfig(message: "这张壁纸已在本地库中", type: .info)
            } else {
                toast = ToastConfig(message: "下载完成，已在本地库中", type: .info)
            }
            return
        }

        isHeroDownloading = true
        NSLog("[HomeView] downloadHero 设置 isHeroDownloading=true")
        defer {
            isHeroDownloading = false
            NSLog("[HomeView] downloadHero defer 设置 isHeroDownloading=false")
        }

        do {
            let wallpaper = try await downloadHeroIfNeeded(item)
            NSLog("[HomeView] downloadHero 下载成功: \(wallpaper.name)")
            SlideshowScheduler.shared.rebuildPlaylist()
            toast = ToastConfig(message: "下载完成，已加入本地库", type: .success)
        } catch {
            NSLog("[HomeView] downloadHero 下载失败: \(error.localizedDescription)")
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

        // 判断壁纸类型：如果有视频 URL 就是视频，否则是图片
        let wallpaperType: WallpaperType = (item.fullVideoURL != nil || item.previewVideoURL != nil) ? .video : .image

        return Wallpaper(
            name: item.title,
            filePath: contentURL,
            type: wallpaperType,
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

    /// 下载远程缩略图到本地缓存
    private func downloadThumbnailToLocal(from url: URL) async -> String? {
        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 10
            request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36", forHTTPHeaderField: "User-Agent")

            let (data, _) = try await URLSession.shared.data(for: request)
            guard let image = NSImage(data: data) else { return nil }

            // 保存到缩略图缓存目录
            let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
            let cacheDir = caches.appendingPathComponent("PlumWallPaper/Thumbnails", isDirectory: true)
            try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)

            let outputURL = cacheDir.appendingPathComponent(UUID().uuidString).appendingPathExtension("jpg")

            // 转换为 JPEG 并保存
            guard let tiffData = image.tiffRepresentation,
                  let bitmap = NSBitmapImageRep(data: tiffData),
                  let jpegData = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.8]) else {
                return nil
            }

            try jpegData.write(to: outputURL)
            NSLog("[HomeView] ✅ 缩略图已下载到本地: \(outputURL.lastPathComponent)")
            return outputURL.path
        } catch {
            NSLog("[HomeView] ❌ 下载缩略图失败: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Hero 壁纸设置

    private func applyCurrentHeroAsWallpaper() async {
        if shouldPromptForIndependentScreenSelection() {
            isChoosingApplyScreen = true
            return
        }
        await applyCurrentHeroAsWallpaper(targetScreenId: nil)
    }

    private func applyCurrentHeroAsWallpaper(targetScreenId: String?) async {
        guard !isApplying, !viewModel.heroItems.isEmpty else { return }

        let currentItem = viewModel.heroItems[currentHeroIndex]

        isApplying = true
        defer { isApplying = false }

        do {
            NSLog("[HomeView] 开始设置壁纸: \(currentItem.title)")

            let wallpaper = try await downloadHeroIfNeeded(currentItem)
            let message = try await applyDownloadedWallpaper(wallpaper, targetScreenId: targetScreenId)
            SlideshowScheduler.shared.rebuildPlaylist()
            toast = ToastConfig(message: message, type: .success)
        } catch {
            NSLog("[HomeView] ❌ 设置壁纸失败: \(error.localizedDescription)")
            toast = ToastConfig(message: "设置失败: \(error.localizedDescription)", type: .error)
        }
    }

    private func applyDownloadedWallpaper(_ wallpaper: Wallpaper, targetScreenId: String?) async throws -> String {
        let settings = try PreferencesStore(modelContext: modelContext).fetchSettings()
        let message = try await WallpaperTopologyCoordinator.shared.apply(
            wallpaper: wallpaper,
            effects: nil,
            settings: settings,
            targetScreenId: targetScreenId
        )
        RestoreManager.shared.saveSession(
            mapping: WallpaperTopologyCoordinator.shared.sessionMapping(
                for: wallpaper.id,
                settings: settings,
                targetScreenId: targetScreenId
            )
        )
        SlideshowScheduler.shared.onWallpaperChanged(wallpaper.id)
        return wallpaper.source == .downloaded ? "已下载并\(message)" : message
    }

    private func shouldPromptForIndependentScreenSelection() -> Bool {
        guard DisplayManager.shared.availableScreens.count > 1 else { return false }
        let settings = (try? PreferencesStore(modelContext: modelContext).fetchSettings()) ?? Settings()
        return settings.displayTopology == .independent
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
