import SwiftUI
import AppKit
import AVFoundation
import SwiftData

// MARK: - Artisan Exhibition Hall (Scheme C: Artisan Gallery)
// 沉浸式壁纸鉴赏厅，UI 仅在鼠标触碰功能区时如雾般浮现。

struct WallpaperDetailView: View {
    @State var wallpaper: Wallpaper
    var onPrevious: ((Wallpaper, @escaping (Wallpaper) -> Void) -> Void)? = nil
    var onNext: ((Wallpaper, @escaping (Wallpaper) -> Void) -> Void)? = nil
    var onFavorite: ((Wallpaper) -> Void)? = nil
    var onDownload: ((Wallpaper) -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    // 状态驱动
    @State private var toastMessage: String?
    @State private var showToast = false
    @State private var isNavigatingWallpaper = false
    @StateObject private var viewModel = WallpaperDetailViewModel()
    @StateObject internal var studio = StudioSessionState()
    @StateObject private var downloadManager = DownloadManager.shared

    // 侧翼导航悬停
    @State internal var isLeftEdgeHovered = false
    @State internal var isRightEdgeHovered = false
    @State private var isCloseHovered = false
    
    @State private var lightningFlash: Double = 0

    @State private var isChoosingApplyScreen = false
    @State private var isCleanPreviewActive = false

    var body: some View {
        ZStack {
            fullscreenCanvas
                .brightness(lightningFlash)
                .allowsHitTesting(false)

            Color.clear
                .contentShape(Rectangle())
                .windowDragGesture()
        }
        .frame(minWidth: 1200, minHeight: 800)
        .overlay {
            if isCleanPreviewActive {
                cleanPreviewExitHUD
                    .transition(.opacity)
            } else {
                chromeOverlay
                    .transition(.opacity)
            }
        }
        .overlay(alignment: .bottomLeading) {
            if !isCleanPreviewActive {
                DownloadProgressOverlay(downloadManager: downloadManager)
            }
        }
        .overlay {
            if !isCleanPreviewActive {
                toastOverlay
            }
        }
        .preferredColorScheme(.dark)
        .onKeyPress(.escape) {
            if isCleanPreviewActive {
                switchToPreviewMode()
                return .handled
            }
            return .ignored
        }
        .task(id: previewCacheTaskID) {
            await viewModel.prepareFullResolutionPreview(for: wallpaper)
        }
        .onAppear {
            viewModel.syncFavoriteDisplayState(for: wallpaper, in: modelContext)
            studio.loadSavedPreset(from: wallpaper)
        }
        .onReceive(NotificationCenter.default.publisher(for: .plumLibraryStateChanged)) { notification in
            guard let stateId = notification.object as? String else {
                viewModel.syncFavoriteDisplayState(for: wallpaper, in: modelContext)
                return
            }
            if stateId == wallpaper.remoteId || stateId == wallpaper.id.uuidString {
                viewModel.syncFavoriteDisplayState(for: wallpaper, in: modelContext)
            }
        }
        .confirmationDialog("选择要应用的屏幕", isPresented: $isChoosingApplyScreen, titleVisibility: .visible) {
            ForEach(DisplayManager.shared.availableScreens) { screen in
                Button("\(screen.name) · \(screen.resolution)") {
                    Task { await applyWallpaper(to: screen.id) }
                }
            }
        }
    }
    
    // MARK: - Subviews

    private var chromeOverlay: some View {
        ZStack {
            HStack {
                if onPrevious != nil {
                    navigationEdgeButton(direction: -1, isHovered: $isLeftEdgeHovered)
                        .transition(.opacity)
                }

                Spacer(minLength: 0)

                if onNext != nil {
                    navigationEdgeButton(direction: 1, isHovered: $isRightEdgeHovered)
                        .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack(spacing: 0) {
                HStack(alignment: .top) {
                    artisanTitleHUD
                        .frame(maxWidth: studio.isStudioActive ? 500 : 720, alignment: .leading)
                        .padding(.leading, 80)
                        .padding(.top, 80)

                    Spacer(minLength: 24)

                    detailModeControls
                        .padding(.top, 48)

                    Spacer(minLength: 24)

                    // Keep the close button in its own corner slot so long titles cannot push it out.
                    Color.clear
                        .frame(width: 88, height: 88)
                        .overlay(alignment: .topTrailing) {
                            closeButtonHUD
                                .padding(.top, 40)
                                .padding(.trailing, 40)
                        }
                }

                Spacer(minLength: 0)

                artisanMainDock
                    .padding(.bottom, 40)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if studio.isStudioActive {
                artisanStudioHUD
                    .padding(.trailing, 52)
                    .padding(.vertical, 86)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
            }
        }
        .zIndex(10)
    }

    private var toastOverlay: some View {
        Group {
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
            }
        }
    }

    private var cleanPreviewExitHUD: some View {
        VStack {
            HStack {
                Spacer()
                Button {
                    switchToPreviewMode()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "rectangle.inset.filled.and.person.filled")
                            .font(.system(size: 12, weight: .bold))
                        Text("退出纯净")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundStyle(.white.opacity(0.74))
                    .padding(.horizontal, 14)
                    .frame(height: 38)
                    .background(.ultraThinMaterial, in: Capsule(style: .continuous))
                    .overlay(Capsule(style: .continuous).stroke(Color.white.opacity(0.14), lineWidth: 0.5))
                }
                .buttonStyle(.plain)
                .help("退出纯净预览，也可以按 Esc")
                .padding(.top, 40)
                .padding(.trailing, 40)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var fullscreenCanvas: some View {
        DetailPreviewCanvas(
            wallpaper: wallpaper,
            contentURL: wallpaperContentURL,
            posterURL: wallpaperPosterURL,
            isStudioActive: studio.isStudioActive,
            effects: studio.renderEffects,
            lightningFlash: $lightningFlash,
            particleColorStart: studio.particleColorStart,
            particleColorEnd: studio.particleColorEnd
        )
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
        .onHover { h in withAnimation(.galleryEase) { isHovered.wrappedValue = h } }
        .keyboardShortcut(direction < 0 ? .leftArrow : .rightArrow, modifiers: [])
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
        // 核心修复：如果没有处理器，直接返回，不锁定状态
        let handler = direction < 0 ? onPrevious : onNext
        guard let action = handler else { return }
        
        guard !isNavigatingWallpaper else { return }
        isNavigatingWallpaper = true
        
        let finish: (Wallpaper) -> Void = { newWallpaper in
            withAnimation(.galleryEase) {
                self.viewModel.resetPreview()
                self.wallpaper = newWallpaper
                self.viewModel.syncFavoriteDisplayState(for: newWallpaper, in: self.modelContext)
                self.studio.resetSession()
                self.studio.loadSavedPreset(from: newWallpaper)
            }
            if newWallpaper.type == .video, let videoURL = WallpaperDetailViewModel.url(from: newWallpaper.filePath) {
                PreviewResourcePipeline.shared.preloadVideo(url: videoURL, intent: .detailFullResolution)
            }
            // 稍作延迟，防止连续疯狂点击导致的逻辑混乱
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isNavigatingWallpaper = false
            }
        }
        
        action(wallpaper, finish)
    }

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
            Text(studio.isStudioActive ? "STUDIO LAB" : "CINEMA PREVIEW")
                .font(.system(size: 12, weight: .black))
                .kerning(5)
                .foregroundStyle(LiquidGlassColors.primaryPink.opacity(studio.isStudioActive ? 0.78 : 1))
            Text(wallpaper.name)
                .artisanTitleStyle(size: studio.isStudioActive ? 40 : 48, kerning: 1)
                .foregroundStyle(.white.opacity(studio.isStudioActive ? 0.74 : 0.96))
                .lineLimit(2)
                .shadow(color: .black.opacity(0.66), radius: 22, x: 0, y: 8)

            // 元信息标签组
            HStack(spacing: 12) {
                if let resolution = wallpaper.resolution {
                    metadataTag(icon: "square.resize", text: resolution)
                }

                if wallpaper.fileSize > 0 {
                    metadataTag(icon: "doc", text: formatFileSize(wallpaper.fileSize))
                }

                if wallpaper.type == .video, let duration = wallpaper.duration {
                    metadataTag(icon: "clock", text: formatDuration(duration))
                }

                if let frameRate = wallpaper.frameRate {
                    metadataTag(icon: "film", text: "\(Int(frameRate))fps")
                }
            }

            // 统计信息（如果有）
            if let metadata = wallpaper.remoteMetadata {
                HStack(spacing: 16) {
                    if let views = metadata.views {
                        metadataTag(icon: "eye", text: formatCount(views))
                    }
                    if let favorites = metadata.favorites {
                        metadataTag(icon: "heart", text: formatCount(favorites))
                    }
                    if let author = metadata.author {
                        metadataTag(icon: "person", text: author)
                    }
                }
            }
        }
    }

    private var detailModeControls: some View {
        HStack(spacing: 8) {
            detailModeIconButton(
                icon: "camera.aperture",
                isActive: studio.isStudioActive,
                help: studio.isStudioActive ? "退出调校" : "进入调校"
            ) {
                if studio.isStudioActive {
                    switchToPreviewMode()
                } else {
                    switchToStudioMode()
                }
            }

            detailModeIconButton(
                icon: "rectangle.inset.filled",
                isActive: isCleanPreviewActive,
                help: "进入纯净预览"
            ) {
                switchToCleanPreviewMode()
            }
        }
    }

    private func detailModeIconButton(icon: String, isActive: Bool, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(isActive ? LiquidGlassColors.primaryPink : .white.opacity(0.5))
                .frame(width: 38, height: 38)
                .background(
                    Circle()
                        .fill(isActive ? LiquidGlassColors.primaryPink.opacity(0.13) : Color.black.opacity(0.16))
                )
                .overlay(
                    Circle()
                        .stroke(isActive ? LiquidGlassColors.primaryPink.opacity(0.38) : Color.white.opacity(0.1), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.2), radius: 14, x: 0, y: 8)
        }
        .buttonStyle(.plain)
        .help(help)
    }

    private func metadataTag(icon: String, text: String) -> some View {
        PlumMetadataChip(icon: icon, text: text)
    }

    private func formatFileSize(_ bytes: Int64) -> String {
        let mb = Double(bytes) / 1024.0 / 1024.0
        if mb >= 1000 {
            return String(format: "%.1fGB", mb / 1024.0)
        }
        return String(format: "%.0fMB", mb)
    }

    private func formatDuration(_ seconds: Double) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: seconds) ?? "0:00"
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

    private var closeButtonHUD: some View {
        Button(action: { dismiss() }) {
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .light))
                .frame(width: 44, height: 44)
                .background(Circle().fill(Color.black.opacity(0.4)))
                .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
        .keyboardShortcut(.escape, modifiers: [])
    }

    private var artisanMainDock: some View {
        DetailActionDock(
            isFavorite: viewModel.isFavoriteDisplayed,
            isApplying: viewModel.isApplying,
            isDownloading: viewModel.isDownloading,
            onFavorite: toggleFavorite,
            onApply: { Task { await applyWallpaper() } },
            onDownload: { Task { await downloadWallpaper() } }
        )
    }

    private func switchToPreviewMode() {
        withAnimation(.gallerySpring) {
            isCleanPreviewActive = false
            studio.isStudioActive = false
            NSColorPanel.shared.orderOut(nil)
        }
    }

    private func switchToStudioMode() {
        withAnimation(.gallerySpring) {
            isCleanPreviewActive = false
            studio.isStudioActive = true
        }
    }

    private func switchToCleanPreviewMode() {
        withAnimation(.gallerySpring) {
            isCleanPreviewActive = true
            studio.isStudioActive = false
            NSColorPanel.shared.orderOut(nil)
        }
    }

    private var artisanStudioHUD: some View {
        DetailStudioPanel(
            isStudioActive: $studio.isStudioActive,
            studioTab: $studio.studioTab,
            exposure: $studio.exposure,
            contrast: $studio.contrast,
            saturation: $studio.saturation,
            hue: $studio.hue,
            blur: $studio.blur,
            grain: $studio.grain,
            vignette: $studio.vignette,
            grayscale: $studio.grayscale,
            invert: $studio.invert,
            highlights: $studio.highlights,
            shadows: $studio.shadows,
            dispersion: $studio.dispersion,
            currentPresetName: $studio.currentPresetName,
            particleStyle: $studio.particleStyle,
            particleRate: $studio.particleRate,
            particleLifetime: $studio.particleLifetime,
            particleSize: $studio.particleSize,
            particleGravity: $studio.particleGravity,
            particleTurbulence: $studio.particleTurbulence,
            particleSpin: $studio.particleSpin,
            particleThrust: $studio.particleThrust,
            particleAngle: $studio.particleAngle,
            particleSpread: $studio.particleSpread,
            particleFadeIn: $studio.particleFadeIn,
            particleFadeOut: $studio.particleFadeOut,
            particleColorStart: $studio.particleColorStart,
            particleColorEnd: $studio.particleColorEnd,
            weatherWind: $studio.weatherWind,
            weatherRain: $studio.weatherRain,
            weatherThunder: $studio.weatherThunder,
            weatherSnow: $studio.weatherSnow,
            studioIntensity: $studio.studioIntensity,
            isExpertExpanded: $studio.isExpertExpanded,
            activeWeatherScene: $studio.activeWeatherScene,
            activeParticleLayer: $studio.activeParticleLayer,
            onApplySmartPreset: { studio.applySmartPreset($0) },
            onApplyWeatherScene: { studio.applyWeatherScene($0) },
            onApplyParticleLayer: { studio.applyParticleLayer($0) },
            onApplyStudioIntensity: { studio.applyStudioIntensity($0) },
            onReset: { studio.resetSession() },
            onSave: applyCurrentPreset
        )
    }

    private var previewCacheTaskID: String {
        WallpaperDetailViewModel.previewTaskID(for: wallpaper)
    }

    private func toggleFavorite() {
        do {
            let newFavoriteState = try viewModel.toggleFavorite(for: wallpaper, in: modelContext)
            showToastMessage(newFavoriteState ? "已加入收藏" : "已取消收藏")
            onFavorite?(wallpaper)
            SlideshowScheduler.shared.rebuildPlaylist()
        } catch {
            NSLog("[WallpaperDetailView] ❌ 收藏保存失败: \(error.localizedDescription)")
            showToastMessage("收藏失败: \(error.localizedDescription)")
        }
    }

    private var wallpaperContentURL: URL? {
        viewModel.contentURL(for: wallpaper)
    }

    private var wallpaperPosterURL: URL? {
        viewModel.posterURL(for: wallpaper)
    }

    private func applyWallpaper() async {
        if shouldPromptForIndependentScreenSelection() {
            isChoosingApplyScreen = true
            return
        }
        await applyWallpaper(to: nil)
    }

    private func applyWallpaper(to screenId: String?) async {
        do {
            let result = try await viewModel.applyWallpaper(
                wallpaper,
                effects: studio.renderEffects,
                targetScreenId: screenId,
                in: modelContext
            )
            wallpaper = result.wallpaper
            if let downloaded = result.downloadedWallpaper {
                onDownload?(downloaded)
            }
            showToastMessage(result.message)
        } catch { showToastMessage("失败: \(error.localizedDescription)") }
    }

    private func downloadWallpaper() async {
        do {
            switch try await viewModel.downloadWallpaper(wallpaper, in: modelContext) {
            case .alreadyLocal:
                showToastMessage("此壁纸已在本地")
            case .downloaded(let downloaded):
                wallpaper = downloaded
                onDownload?(downloaded)
                showToastMessage("下载完成")
            }
        } catch {
            showToastMessage("失败: \(error.localizedDescription)")
        }
    }

    private func applyCurrentPreset() {
        if wallpaper.shaderPreset == nil {
            wallpaper.shaderPreset = ShaderPreset(name: studio.currentPresetName)
        } else {
            wallpaper.shaderPreset?.name = studio.currentPresetName
        }
        wallpaper.shaderPreset?.passes = studio.shaderPasses
        try? modelContext.save()
        showToastMessage("已保存实验室参数")
    }

    private func showToastMessage(_ message: String) {
        toastMessage = message; showToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { withAnimation { showToast = false } }
    }

    private func shouldPromptForIndependentScreenSelection() -> Bool {
        guard DisplayManager.shared.availableScreens.count > 1 else { return false }
        let settings = (try? PreferencesStore(modelContext: modelContext).fetchSettings()) ?? Settings()
        return settings.displayTopology == .independent
    }
}
