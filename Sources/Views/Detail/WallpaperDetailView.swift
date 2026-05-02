import SwiftUI
import AppKit
import AVFoundation

// MARK: - Artisan Exhibition Hall (Scheme C: Artisan Gallery)
// 沉浸式壁纸鉴赏厅，UI 仅在鼠标触碰功能区时如雾般浮现。

struct WallpaperDetailView: View {
    @State var wallpaper: Wallpaper // 改为 @State 以支持内部平滑更新
    var onPrevious: ((Wallpaper, @escaping (Wallpaper) -> Void) -> Void)? = nil
    var onNext: ((Wallpaper, @escaping (Wallpaper) -> Void) -> Void)? = nil
    var onFavorite: ((Wallpaper) -> Void)? = nil
    var onDownload: ((Wallpaper) -> Void)? = nil
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    // 状态驱动
    @State internal var isStudioActive = false      // 实验室面板是否展开
    @State internal var studioTab = 0               // 0: 预设, 1: 光学, 2: 风格, 3: 粒子
    @State internal var isApplying = false           // 应用壁纸中
    @State private var isDownloading = false
    @State private var toastMessage: String?
    @State private var showToast = false
    @State private var isNavigatingWallpaper = false

    // 侧翼导航悬停
    @State internal var isLeftEdgeHovered = false
    @State internal var isRightEdgeHovered = false
    
    // 滤镜状态 (保留现有变量名)
    @State internal var exposure: Double = 100
    @State internal var contrast: Double = 100
    @State internal var saturation: Double = 100
    @State internal var hue: Double = 0
    @State internal var blur: Double = 0
    @State internal var grain: Double = 0
    @State internal var vignette: Double = 0
    @State internal var grayscale: Double = 0
    @State internal var invert: Double = 0
    @State internal var currentPresetName: String = "原图"

    // 粒子系统状态
    @State private var particleRate: Double = 60
    @State private var particleLifetime: Double = 3
    @State private var particleSize: Double = 4
    @State private var particleGravity: Double = 9.8
    @State private var particleTurbulence: Double = 2
    @State private var particleColorStart = Color.white
    @State private var particleColorEnd = LiquidGlassColors.primaryPink

    @State var isShowingShaderEditor = false
    
    var body: some View {
        Group {
            if wallpaper.type == .video, let videoURL = wallpaperContentURL {
                DetailVideoLayerContainer(url: videoURL) {
                    detailChrome(includeStaticCanvas: false)
                }
                .id(videoURL.absoluteString)
            } else {
                detailChrome(includeStaticCanvas: true)
            }
        }
        .sheet(isPresented: $isShowingShaderEditor) {
            ShaderEditorView()
        }
        .frame(minWidth: 1200, minHeight: 800)
        .preferredColorScheme(.dark)
        .onAppear {
            if wallpaper.type == .video, let videoURL = wallpaperContentURL {
                VideoPreloader.shared.preload(url: videoURL)
            }
        }
    }

    @ViewBuilder
    private func detailChrome(includeStaticCanvas: Bool) -> some View {
        ZStack {
            // 1. 底层：纯净画布（100% 视野）
            if includeStaticCanvas {
                fullscreenCanvas
                    .allowsHitTesting(false)
                    .zIndex(-100)
            } else {
                RadialGradient(colors: [.clear, .black.opacity(0.3)], center: .center, startRadius: 300, endRadius: 1000)
                    .allowsHitTesting(false)
                    .zIndex(-100)
            }

            // 2. 交互辅助层：透明拖拽与背景点击
            Color.clear.contentShape(Rectangle()).windowDragGesture()
                .zIndex(0)

            // 3. 侧翼导航（左右两侧边缘感应）
            sideNavigationArrows
                .zIndex(10) // 降低层级，确保不遮挡 Dock 和 Studio

            // 4. 标题 HUD（左上角，极简感应）
            artisanTitleHUD
                .padding(.leading, 80).padding(.top, 80)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            // 5. 核心地平线 HUD（Dock + Studio，底部居中）
            VStack(spacing: 24) {
                Spacer()

                // 次地平线：调节工作室（点击"实验室"按钮后升起）
                if isStudioActive {
                    artisanStudioHUD
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .opacity
                        ))
                        .zIndex(50)
                }

                // 地平线底座：主控 Dock
                artisanMainDock
                    .zIndex(60)
            }
            .padding(.bottom, 40)
            .zIndex(100) // 整体地平线 HUD 拥有最高点击优先级

            // 7. Toast 通知
            if showToast, let message = toastMessage {
                VStack {
                    Spacer()
                    Text(message)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(.ultraThinMaterial))
                        .padding(.bottom, 120)
                }
                .transition(.opacity)
                .zIndex(200)
            }

            // 6. 关闭按钮（右上角）
            closeButtonHUD
                .zIndex(1000)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - A. 视觉子层级 (Artisan Horizon HUD)
    
    private var fullscreenCanvas: some View {
        ZStack {
            if wallpaper.type == .video, let videoURL = wallpaperContentURL {
                VideoPlayer(url: videoURL, posterURL: wallpaperPosterURL)
                    .id(videoURL.absoluteString)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            } else if let url = wallpaperContentURL {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable().aspectRatio(contentMode: .fill)
                    } else {
                        fallbackPoster
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
            } else {
                fallbackPoster
            }
            // 径向暗角
            RadialGradient(colors: [.clear, .black.opacity(0.3)], center: .center, startRadius: 300, endRadius: 1000)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .ignoresSafeArea()
        .onAppear {
            if wallpaper.type == .video, let videoURL = wallpaperContentURL {
                VideoPreloader.shared.preload(url: videoURL)
            }
        }
    }

    private var fallbackPoster: some View {
        ZStack {
            Color.black
            if let posterURL = wallpaperPosterURL {
                AsyncImage(url: posterURL) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .blur(radius: 16)
                            .opacity(0.45)
                    } else {
                        Color.black
                    }
                }
            }
        }
    }

    private var wallpaperContentURL: URL? {
        url(from: wallpaper.filePath)
    }

    private var wallpaperPosterURL: URL? {
        guard let thumbnailPath = wallpaper.thumbnailPath else { return nil }
        return url(from: thumbnailPath)
    }

    private func url(from path: String) -> URL? {
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let url = URL(string: trimmed), url.scheme != nil {
            return url
        }

        return URL(fileURLWithPath: trimmed)
    }

    private var sideNavigationArrows: some View {
        HStack(spacing: 0) {
            navigationEdgeButton(direction: -1, isHovered: $isLeftEdgeHovered)

            Spacer(minLength: 0)

            navigationEdgeButton(direction: 1, isHovered: $isRightEdgeHovered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func navigationEdgeButton(direction: Int, isHovered: Binding<Bool>) -> some View {
        Button {
            navigateWallpaper(direction: direction)
        } label: {
            ZStack {
                Color.black.opacity(0.001)

                navigationChevron(isPrevious: direction < 0)
                    .frame(width: 14, height: 44)
                    .opacity(isHovered.wrappedValue ? 1 : 0.72)
                    .offset(x: direction < 0 ? 28 : -28)
            }
            .frame(width: 160)
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isNavigatingWallpaper)
        .onHover { hovering in
            withAnimation(.galleryEase) {
                isHovered.wrappedValue = hovering
            }
        }
    }

    private func navigationChevron(isPrevious: Bool) -> some View {
        ZStack {
            RoundedChevron()
                .stroke(LiquidGlassColors.primaryPink.opacity(0.3), style: StrokeStyle(lineWidth: 12, lineCap: .round, lineJoin: .round))
                .blur(radius: 8)

            RoundedChevron()
                .stroke(.white.opacity(0.6), style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)

            RoundedChevron()
                .stroke(
                    LinearGradient(colors: [.white, .white.opacity(0.2)], startPoint: .top, endPoint: .bottom),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                )
        }
        .rotationEffect(.degrees(isPrevious ? 180 : 0))
    }

    private func navigateWallpaper(direction: Int) {
        guard !isNavigatingWallpaper else { return }
        isNavigatingWallpaper = true

        let finish: (Wallpaper) -> Void = { newWallpaper in
            withAnimation(.galleryEase) {
                self.wallpaper = newWallpaper
            }

            if newWallpaper.type == .video, let videoURL = url(from: newWallpaper.filePath) {
                VideoPreloader.shared.preload(url: videoURL)
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                isNavigatingWallpaper = false
            }
        }

        if direction < 0 {
            if let onPrevious {
                onPrevious(wallpaper, finish)
            } else {
                isNavigatingWallpaper = false
            }
        } else {
            if let onNext {
                onNext(wallpaper, finish)
            } else {
                isNavigatingWallpaper = false
            }
        }
    }

    // 自定义圆润箭头图形
    private struct RoundedChevron: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: rect.width, y: rect.height / 2))
            path.addLine(to: CGPoint(x: 0, y: rect.height))
            return path
        }
    }

    private var artisanTitleHUD: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("精选画廊")
                .font(.system(size: 12, weight: .black)).kerning(5)
                .foregroundStyle(LiquidGlassColors.primaryPink)

            Text(wallpaper.name)
                .artisanTitleStyle(size: 48, kerning: 1)
                .shadow(color: .black.opacity(0.5), radius: 20)

            HStack(spacing: 20) {
                metadataTag(icon: "ruler", text: wallpaper.resolution ?? "8K 超清")
                metadataTag(icon: "cpu", text: "全动态渲染")
            }
        }
    }

    private func metadataTag(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 10))
            Text(text).font(.system(size: 10, weight: .bold))
        }
        .foregroundStyle(.white.opacity(0.6))
        .padding(.horizontal, 12).padding(.vertical, 6)
        .background(Capsule().fill(Color.white.opacity(0.05)))
    }

    private var artisanMainDock: some View {
        HStack(spacing: 24) {
            // 1. 收藏按钮（圆形）
            actionCircleButton(
                icon: wallpaper.isFavorite ? "heart.fill" : "heart",
                color: wallpaper.isFavorite ? LiquidGlassColors.primaryPink : .white.opacity(0.6)
            ) {
                wallpaper.isFavorite.toggle()
                
                do {
                    var targetToSave = wallpaper
                    
                    // 如果它已经在数据库里（本地库里的壁纸），直接保存
                    if wallpaper.modelContext != nil {
                        try modelContext.save()
                    } else {
                        // 如果它是临时的包装对象（在线预览），去数据库里找找看是不是已经存在了
                        if let remoteId = wallpaper.remoteId,
                           let existing = DownloadManager.shared.isAlreadyDownloaded(remoteId: remoteId, context: modelContext) {
                            existing.isFavorite = wallpaper.isFavorite
                            targetToSave = existing
                            try modelContext.save()
                        } else {
                            // 既不在数据库，也是首次收藏的在线壁纸
                            modelContext.insert(wallpaper)
                            try modelContext.save()
                        }
                    }
                    
                    onFavorite?(targetToSave)
                } catch {
                    NSLog("[WallpaperDetailView] 保存收藏状态失败: \(error)")
                }
            }

            // 2. 应用壁纸（主按钮，粉色胶囊）
            Button(action: {
                Task {
                    await applyWallpaper()
                }
            }) {
                HStack(spacing: 16) {
                    if isApplying { CustomProgressView(tint: .white, scale: 0.8) }
                    else { Text("设为壁纸").font(.system(size: 14, weight: .bold)).kerning(2) }
                }
                .padding(.horizontal, 60).frame(height: 52)
                .background(LiquidGlassColors.primaryPink)
                .clipShape(Capsule())
                .foregroundStyle(.black)
                .artisanShadow(color: LiquidGlassColors.primaryPink.opacity(0.3), radius: 20)
            }
            .buttonStyle(.plain)
            .disabled(isApplying)

            // 3. 实验室按钮（圆形，toggle 控制 isStudioActive）
            Button(action: { withAnimation(.gallerySpring) { isStudioActive.toggle() } }) {
                VStack(spacing: 4) {
                    Image(systemName: "camera.aperture").font(.system(size: 18))
                    Text("实验室").font(.system(size: 8, weight: .bold))
                }
                .foregroundStyle(isStudioActive ? LiquidGlassColors.primaryPink : .white.opacity(0.6))
                .frame(width: 52, height: 52)
                .background(Circle().fill(Color.white.opacity(0.05)))
                .overlay(Circle().stroke(
                    isStudioActive ? LiquidGlassColors.primaryPink.opacity(0.5) : Color.white.opacity(0.1),
                    lineWidth: 1
                ))
            }.buttonStyle(.plain)

            // 4. 下载按钮（圆形）
            actionCircleButton(icon: "arrow.down.to.line.compact", color: .white.opacity(0.6)) {
                Task {
                    await downloadWallpaper()
                }
            }
            .disabled(isDownloading)
        }
        .padding(12)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 0.5))
        .artisanShadow(color: .black.opacity(0.2), radius: 30)
    }

    private var artisanStudioHUD: some View {
        HStack(spacing: 40) {
            // === 左侧：Tab 切换按钮（竖排） ===
            VStack(spacing: 12) {
                ArtisanHorizonTab(icon: "grid", label: "预设", isSelected: studioTab == 0) { studioTab = 0 }
                ArtisanHorizonTab(icon: "camera.filters", label: "光学", isSelected: studioTab == 1) { studioTab = 1 }
                ArtisanHorizonTab(icon: "crop", label: "风格", isSelected: studioTab == 2) { studioTab = 2 }
                ArtisanHorizonTab(icon: "sparkles", label: "粒子", isSelected: studioTab == 3) { studioTab = 3 }
            }

            Divider().frame(height: 140).opacity(0.1)

            // === 中间：对应 Tab 的内容区（横向滚动） ===
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 32) {
                    if studioTab == 0 {
                        // 预设 Tab：快速滤镜网格
                        presetTabContent
                    } else if studioTab == 1 {
                        // 光学 Tab：曝光/对比度/饱和度/色相
                        ArtisanRulerDial(label: "曝光", value: $exposure, range: 0...200, unit: "ev")
                        ArtisanRulerDial(label: "对比度", value: $contrast, range: 50...150, unit: "%")
                        ArtisanRulerDial(label: "饱和度", value: $saturation, range: 0...200, unit: "%")
                        ArtisanRulerDial(label: "色相", value: $hue, range: -180...180, unit: "°")
                    } else if studioTab == 2 {
                        // 风格 Tab：模糊/噪点/暗角/黑白/反相
                        ArtisanRulerDial(label: "模糊", value: $blur, range: 0...40, unit: "px")
                        ArtisanRulerDial(label: "噪点", value: $grain, range: 0...100, unit: "%")
                        ArtisanRulerDial(label: "暗角", value: $vignette, range: 0...100, unit: "%")
                        ArtisanRulerDial(label: "黑白", value: $grayscale, range: 0...100, unit: "%")
                        ArtisanRulerDial(label: "反相", value: $invert, range: 0...100, unit: "%")
                    } else if studioTab == 3 {
                        // 粒子 Tab
                        particleTabContent
                    }
                }
                .padding(.vertical, 10)
            }
            .frame(maxWidth: 750)

            Divider().frame(height: 140).opacity(0.1)

            // === 右侧：重置/应用按钮 ===
            VStack(spacing: 16) {
                Button(action: { resetFilters() }) {
                    VStack(spacing: 4) {
                        Image(systemName: "arrow.counterclockwise.circle.fill").font(.system(size: 20))
                        Text("重置").font(.system(size: 8, weight: .bold))
                    }.foregroundStyle(.white.opacity(0.4))
                }.buttonStyle(.plain)

                Button(action: { applyCurrentPreset() }) {
                    VStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill").font(.system(size: 20))
                        Text("应用").font(.system(size: 8, weight: .bold))
                    }.foregroundStyle(LiquidGlassColors.primaryPink)
                }.buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 32).padding(.vertical, 24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 32))
        .overlay(RoundedRectangle(cornerRadius: 32).stroke(Color.white.opacity(0.12), lineWidth: 0.5))
        .artisanShadow(color: .black.opacity(0.4), radius: 50)
    }

    private var presetTabContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("快速滤镜").font(.system(size: 10, weight: .bold)).foregroundStyle(.white.opacity(0.3))
            LazyHGrid(rows: [GridItem(.fixed(32)), GridItem(.fixed(32))], spacing: 10) {
                ForEach(BuiltInPreset.allCases) { preset in
                    Button(action: { applyPreset(preset) }) {
                        Text(preset.name).font(.system(size: 11, weight: .bold))
                            .padding(.horizontal, 16).frame(height: 32)
                            .background(currentPresetName == preset.name
                                ? LiquidGlassColors.primaryPink
                                : Color.white.opacity(0.08))
                            .foregroundStyle(currentPresetName == preset.name ? Color.black : .white)
                            .clipShape(Capsule())
                    }.buttonStyle(.plain)
                }
            }
        }
    }

    private var particleTabContent: some View {
        HStack(spacing: 40) {
            // 发射源
            VStack(spacing: 8) {
                Text("发射源").font(.system(size: 8, weight: .bold)).opacity(0.3)
                Button(action: {}) {
                    Circle().fill(LiquidGlassColors.primaryPink).frame(width: 36, height: 36)
                        .overlay(Image(systemName: "plus").font(.system(size: 14, weight: .bold)).foregroundStyle(.black))
                }.buttonStyle(.plain)
            }

            Divider().frame(height: 60).opacity(0.1)

            // 粒子样式选择
            VStack(alignment: .leading, spacing: 12) {
                Text("粒子样式").font(.system(size: 8, weight: .bold)).opacity(0.3)
                HStack(spacing: 12) {
                    ForEach(["circle.fill", "star.fill", "sparkles", "leaf.fill", "drop.fill"], id: \.self) { icon in
                        Image(systemName: icon).font(.system(size: 14))
                            .foregroundStyle(icon == "circle.fill" ? LiquidGlassColors.primaryPink : .white.opacity(0.4))
                            .frame(width: 32, height: 32)
                            .background(icon == "circle.fill" ? Color.white.opacity(0.1) : Color.clear)
                            .clipShape(Circle())
                    }
                }
            }

            Divider().frame(height: 60).opacity(0.1)

            // 色彩演化
            VStack(alignment: .leading, spacing: 12) {
                Text("色彩演化").font(.system(size: 8, weight: .bold)).opacity(0.3)
                HStack(spacing: 12) {
                    ColorPicker("", selection: $particleColorStart).labelsHidden()
                    Image(systemName: "arrow.right").font(.system(size: 8)).opacity(0.2)
                    ColorPicker("", selection: $particleColorEnd).labelsHidden()
                }
            }

            Divider().frame(height: 60).opacity(0.1)

            // 粒子参数旋钮
            ArtisanRulerDial(label: "速率", value: $particleRate, range: 1...300, unit: "p/s")
            ArtisanRulerDial(label: "寿命", value: $particleLifetime, range: 0.1...10, unit: "s")
            ArtisanRulerDial(label: "尺寸", value: $particleSize, range: 1...40, unit: "px")
            ArtisanRulerDial(label: "重力", value: $particleGravity, range: -20...20, unit: "m/s²")
            ArtisanRulerDial(label: "扰动", value: $particleTurbulence, range: 0...20, unit: "px")
        }
    }
    
    private var closeButtonHUD: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .light))
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Color.black.opacity(0.4)))
                        .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 0.5))
                }
                .buttonStyle(.plain).padding(40)
            }
            Spacer()
        }.zIndex(110)
    }

    // MARK: - 辅助组件
    
    private func actionCircleButton(icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).font(.system(size: 18)).foregroundStyle(color)
                .frame(width: 52, height: 52)
                .background(Circle().fill(Color.white.opacity(0.05)))
                .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
        }.buttonStyle(.plain)
    }

    // MARK: - Actions

    private func applyWallpaper() async {
        isApplying = true
        defer { isApplying = false }

        NSLog("[WallpaperDetailView] applyWallpaper type=\(wallpaper.type) filePath=\(wallpaper.filePath)")

        do {
            if wallpaper.type == .video {
                // 视频壁纸：通过 RenderPipeline 渲染到桌面
                let videoURL: URL
                let wallpaperVideoPath = highQualityVideoPathForApply ?? wallpaper.filePath
                if let remoteURL = URL(string: wallpaperVideoPath), remoteURL.scheme?.hasPrefix("http") == true {
                    // 远程视频：先下载到临时目录
                    let tempDir = FileManager.default.temporaryDirectory
                    let ext = "mp4"
                    let filename = "\(wallpaper.id.uuidString).\(ext)"
                    let localURL = tempDir.appendingPathComponent(filename)

                    if !FileManager.default.fileExists(atPath: localURL.path) {
                        NSLog("[WallpaperDetailView] 下载远程视频...")
                        let (data, _) = try await URLSession.shared.data(from: remoteURL)
                        try data.write(to: localURL)
                        NSLog("[WallpaperDetailView] ✅ 视频下载完成 \(data.count) bytes -> \(localURL.path)")
                    }
                    videoURL = localURL
                } else {
                    // 本地文件路径
                    videoURL = URL(fileURLWithPath: wallpaperVideoPath)
                }

                try await RenderPipeline.shared.setWallpaper(url: videoURL)
                showToastMessage("动态壁纸设置成功")
            } else {
                // 静态壁纸：通过 WallpaperSetter 设置系统壁纸
                if let remoteURL = URL(string: wallpaper.filePath), remoteURL.scheme?.hasPrefix("http") == true {
                    let imageURL = remoteURL
                    let tempDir = FileManager.default.temporaryDirectory
                    let filename = "\(wallpaper.id.uuidString).jpg"
                    let localURL = tempDir.appendingPathComponent(filename)

                    if !FileManager.default.fileExists(atPath: localURL.path) {
                        let (data, _) = try await URLSession.shared.data(from: imageURL)
                        try data.write(to: localURL)
                    }

                    try await MainActor.run {
                        try WallpaperSetter.shared.setWallpaper(imageURL: localURL)
                    }
                } else {
                    let localURL = URL(fileURLWithPath: wallpaper.filePath)
                    try await MainActor.run {
                        try WallpaperSetter.shared.setWallpaper(imageURL: localURL)
                    }
                }

                showToastMessage("壁纸设置成功")
            }
        } catch {
            showToastMessage("设置失败: \(error.localizedDescription)")
        }
    }

    private var highQualityVideoPathForApply: String? {
        guard let value = wallpaper.downloadQuality,
              let url = URL(string: value),
              url.scheme?.hasPrefix("http") == true else {
            return nil
        }
        return value
    }

    private func downloadWallpaper() async {
        guard let remoteURL = URL(string: wallpaper.filePath), remoteURL.scheme?.hasPrefix("http") == true else {
            showToastMessage("此壁纸已在本地")
            return
        }

        // 检查是否已下载
        if let remoteId = wallpaper.remoteId,
           DownloadManager.shared.isAlreadyDownloaded(remoteId: remoteId, context: modelContext) != nil {
            showToastMessage("已下载过此壁纸")
            return
        }

        isDownloading = true
        defer { isDownloading = false }

        do {
            // 优先使用原图下载，而非缩略图
            let imageURL = remoteURL
            let downloadsDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
                .appendingPathComponent("PlumWallPaper/Downloads", isDirectory: true)
            try FileManager.default.createDirectory(at: downloadsDir, withIntermediateDirectories: true)

            let ext = wallpaper.type == .video ? "mp4" : "jpg"
            let sanitizedName = wallpaper.name.replacingOccurrences(of: "[^a-zA-Z0-9]", with: "_", options: .regularExpression).prefix(50)
            let filename = "\(sanitizedName)_\(wallpaper.id.uuidString.prefix(8)).\(ext)"
            let localURL = downloadsDir.appendingPathComponent(filename)

            let (data, _) = try await URLSession.shared.data(from: imageURL)
            try data.write(to: localURL)

            // 持久化到 SwiftData
            let newWallpaper = Wallpaper(
                name: wallpaper.name,
                filePath: localURL.path,
                type: wallpaper.type,
                resolution: wallpaper.resolution,
                fileSize: Int64(data.count),
                thumbnailPath: wallpaper.thumbnailPath,
                source: .downloaded,
                remoteId: wallpaper.remoteId,
                remoteSource: wallpaper.remoteSource,
                remoteMetadata: wallpaper.remoteMetadata
            )
            modelContext.insert(newWallpaper)
            try modelContext.save()

            wallpaper.filePath = localURL.path
            wallpaper.source = .downloaded

            onDownload?(wallpaper)
            showToastMessage("下载完成")
        } catch {
            showToastMessage("下载失败: \(error.localizedDescription)")
        }
    }

    private func applyCurrentPreset() {
        showToastMessage("滤镜已应用（渲染引擎待实现）")
    }

    private func showToastMessage(_ message: String) {
        toastMessage = message
        showToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation { showToast = false }
        }
    }
}

private struct DetailVideoLayerContainer<Overlay: View>: NSViewRepresentable {
    let url: URL
    @ViewBuilder var overlay: () -> Overlay

    func makeNSView(context: Context) -> DetailVideoLayerView<Overlay> {
        let view = DetailVideoLayerView(rootView: overlay())
        view.configure(url: url)
        return view
    }

    func updateNSView(_ nsView: DetailVideoLayerView<Overlay>, context: Context) {
        nsView.hostingView.rootView = overlay()
        nsView.configure(url: url)
    }

    static func dismantleNSView(_ nsView: DetailVideoLayerView<Overlay>, coordinator: ()) {
        nsView.stop()
    }
}

private final class DetailVideoLayerView<Overlay: View>: NSView {
    private let playerLayer = AVPlayerLayer()
    private var player: AVPlayer?
    private var currentURL: URL?
    private var endObserver: NSObjectProtocol?
    let hostingView: NSHostingView<Overlay>

    init(rootView: Overlay) {
        hostingView = NSHostingView(rootView: rootView)
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        wantsLayer = true
        let rootLayer = CALayer()
        rootLayer.backgroundColor = NSColor.black.cgColor
        rootLayer.masksToBounds = true
        layer = rootLayer

        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.needsDisplayOnBoundsChange = true
        rootLayer.addSublayer(playerLayer)

        hostingView.translatesAutoresizingMaskIntoConstraints = false
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        addSubview(hostingView)

        NSLayoutConstraint.activate([
            hostingView.leadingAnchor.constraint(equalTo: leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: trailingAnchor),
            hostingView.topAnchor.constraint(equalTo: topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    func configure(url: URL) {
        guard currentURL != url else { return }
        currentURL = url

        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
            self.endObserver = nil
        }

        player?.pause()
        let playerItem = AVPlayerItem(url: url)
        playerItem.preferredForwardBufferDuration = 3
        playerItem.canUseNetworkResourcesForLiveStreamingWhilePaused = true

        let nextPlayer = AVPlayer(playerItem: playerItem)
        nextPlayer.isMuted = false
        nextPlayer.volume = 1.0
        nextPlayer.automaticallyWaitsToMinimizeStalling = false

        player = nextPlayer
        playerLayer.player = nextPlayer
        nextPlayer.play()

        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            guard self?.currentURL == url else { return }
            nextPlayer.seek(to: .zero)
            nextPlayer.play()
        }
    }

    func stop() {
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
            self.endObserver = nil
        }
        player?.pause()
        playerLayer.player = nil
        player = nil
        currentURL = nil
    }

    override func layout() {
        super.layout()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        playerLayer.frame = bounds
        CATransaction.commit()
    }
}

// MARK: - 内置预设
enum BuiltInPreset: String, CaseIterable, Identifiable {
    case original, vivid, warm, cool, noir, vintage, cinematic, fade
    var id: Self { self }

    var name: String {
        switch self {
        case .original: return "原图"
        case .vivid: return "鲜艳"
        case .warm: return "暖色"
        case .cool: return "冷色"
        case .noir: return "黑白"
        case .vintage: return "复古"
        case .cinematic: return "电影"
        case .fade: return "褪色"
        }
    }

    var exposure: Double {
        switch self {
        case .original: return 100
        case .vivid: return 110
        case .warm: return 105
        case .cool: return 95
        case .noir: return 100
        case .vintage: return 90
        case .cinematic: return 85
        case .fade: return 80
        }
    }

    var contrast: Double {
        switch self {
        case .original: return 100
        case .vivid: return 120
        case .warm: return 105
        case .cool: return 105
        case .noir: return 130
        case .vintage: return 90
        case .cinematic: return 110
        case .fade: return 70
        }
    }

    var saturation: Double {
        switch self {
        case .original: return 100
        case .vivid: return 150
        case .warm: return 120
        case .cool: return 90
        case .noir: return 0
        case .vintage: return 70
        case .cinematic: return 80
        case .fade: return 50
        }
    }

    var hue: Double {
        switch self {
        case .original: return 0
        case .vivid: return 0
        case .warm: return 15
        case .cool: return -15
        case .noir: return 0
        case .vintage: return 20
        case .cinematic: return -10
        case .fade: return 0
        }
    }

    var blur: Double {
        switch self {
        case .original: return 0
        case .vivid: return 0
        case .warm: return 0
        case .cool: return 0
        case .noir: return 0
        case .vintage: return 1
        case .cinematic: return 0.5
        case .fade: return 2
        }
    }

    var grain: Double {
        switch self {
        case .original: return 0
        case .vivid: return 0
        case .warm: return 5
        case .cool: return 0
        case .noir: return 20
        case .vintage: return 40
        case .cinematic: return 15
        case .fade: return 10
        }
    }

    var vignette: Double {
        switch self {
        case .original: return 0
        case .vivid: return 0
        case .warm: return 10
        case .cool: return 15
        case .noir: return 30
        case .vintage: return 40
        case .cinematic: return 50
        case .fade: return 20
        }
    }

    var grayscale: Double {
        switch self {
        case .original: return 0
        case .vivid: return 0
        case .warm: return 0
        case .cool: return 0
        case .noir: return 100
        case .vintage: return 0
        case .cinematic: return 0
        case .fade: return 30
        }
    }

    var invert: Double {
        switch self {
        case .original: return 0
        case .vivid: return 0
        case .warm: return 0
        case .cool: return 0
        case .noir: return 0
        case .vintage: return 0
        case .cinematic: return 0
        case .fade: return 0
        }
    }
}
