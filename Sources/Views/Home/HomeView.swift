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
    @State private var isHeroLeftHovered = false
    @State private var isHeroRightHovered = false

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
    }

    private func preheatHomeVideos() {
        preheatHeroVideos()
        let motionURLs = viewModel.popularMotions.compactMap(primaryVideoURL(for:))
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
            .compactMap(primaryVideoURL(for:))

        VideoPreloader.shared.preload(urls: urls, limit: 3)
    }

    private func primaryVideoURL(for item: MediaItem) -> URL? {
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
                    if let videoURL = item.previewVideoURL ?? item.fullVideoURL {
                        HeroVideoPlayer(url: videoURL, isActive: true)
                        .id(videoURL.absoluteString)
                        .frame(width: size.width, height: size.height)
                        .clipped()
                    } else {
                        AsyncImage(url: item.thumbnailURL) { phase in
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
                        let wallpaper = Wallpaper.from(remote: remoteWallpaper)
                        WallpaperCard(wallpaper: wallpaper, onTap: {
                            detailWallpaper = wallpaper
                        }, onDownload: {
                            Task {
                                await downloadFromCard(wallpaper)
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
                                await downloadFromCard(wallpaper)
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

    // MARK: - 快捷下载

    private func downloadFromCard(_ wallpaper: Wallpaper) async {
        guard let remoteURL = URL(string: wallpaper.filePath), remoteURL.scheme?.hasPrefix("http") == true else {
            return
        }

        do {
            let imageURL = URL(string: wallpaper.thumbnailPath ?? wallpaper.filePath) ?? remoteURL
            let downloadsDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
                .appendingPathComponent("PlumWallPaper/Downloads", isDirectory: true)
            try FileManager.default.createDirectory(at: downloadsDir, withIntermediateDirectories: true)

            let ext = wallpaper.type == .video ? "mp4" : "jpg"
            let sanitizedName = wallpaper.name.replacingOccurrences(of: "[^a-zA-Z0-9]", with: "_", options: .regularExpression).prefix(50)
            let filename = "\(sanitizedName)_\(wallpaper.id.uuidString.prefix(8)).\(ext)"
            let localURL = downloadsDir.appendingPathComponent(filename)

            let (data, _) = try await URLSession.shared.data(from: imageURL)
            try data.write(to: localURL)

            NSLog("[HomeView] ✅ 快捷下载完成: \(localURL.path)")
        } catch {
            NSLog("[HomeView] ❌ 快捷下载失败: \(error.localizedDescription)")
        }
    }

    // MARK: - Hero 壁纸设置

    private func applyCurrentHeroAsWallpaper() async {
        guard !viewModel.heroItems.isEmpty else { return }

        let currentItem = viewModel.heroItems[currentHeroIndex]

        isApplying = true
        defer { isApplying = false }

        do {
            NSLog("[HomeView] 开始设置壁纸: \(currentItem.title)")

            if let videoURL = currentItem.fullVideoURL ?? currentItem.previewVideoURL {
                // 视频壁纸：通过 RenderPipeline 渲染到桌面
                let tempDir = FileManager.default.temporaryDirectory
                let filename = "\(currentItem.slug).mp4"
                let localURL = tempDir.appendingPathComponent(filename)

                if !FileManager.default.fileExists(atPath: localURL.path) {
                    NSLog("[HomeView] 下载视频: \(videoURL.absoluteString)")
                    let (data, _) = try await URLSession.shared.data(from: videoURL)
                    try data.write(to: localURL)
                    NSLog("[HomeView] ✅ 视频下载完成: \(localURL.path)")
                }

                try await RenderPipeline.shared.setWallpaper(url: localURL)
                NSLog("[HomeView] ✅ 动态壁纸设置成功")
            } else {
                // 静态壁纸：使用 posterURL 高清图
                let imageURL = currentItem.posterURL ?? currentItem.thumbnailURL
                let tempDir = FileManager.default.temporaryDirectory
                let filename = "\(currentItem.slug).jpg"
                let localURL = tempDir.appendingPathComponent(filename)

                if !FileManager.default.fileExists(atPath: localURL.path) {
                    NSLog("[HomeView] 下载图片: \(imageURL.absoluteString)")
                    let (data, _) = try await URLSession.shared.data(from: imageURL)
                    try data.write(to: localURL)
                    NSLog("[HomeView] ✅ 下载完成: \(localURL.path)")
                }

                try await MainActor.run {
                    try WallpaperSetter.shared.setWallpaper(imageURL: localURL)
                }
                NSLog("[HomeView] ✅ 壁纸设置成功")
            }
        } catch {
            NSLog("[HomeView] ❌ 设置壁纸失败: \(error.localizedDescription)")
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
