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
    @State internal var isStudioActive = false      
    @State internal var studioTab = 0               
    @State internal var isApplying = false           
    @State private var toastMessage: String?
    @State private var showToast = false
    @State private var isNavigatingWallpaper = false
    @StateObject private var downloadManager = DownloadManager.shared
    @StateObject private var viewModel = WallpaperDetailViewModel()

    // 侧翼导航悬停
    @State internal var isLeftEdgeHovered = false
    @State internal var isRightEdgeHovered = false
    @State private var isCloseHovered = false
    
    // 滤镜状态
    @State internal var exposure: Double = 100
    @State internal var contrast: Double = 100
    @State internal var saturation: Double = 100
    @State internal var hue: Double = 0
    @State internal var blur: Double = 0
    @State internal var grain: Double = 0
    @State internal var vignette: Double = 0
    @State internal var grayscale: Double = 0
    @State internal var invert: Double = 0
    @State internal var highlights: Double = 100
    @State internal var shadows: Double = 100
    @State internal var dispersion: Double = 0
    @State internal var currentPresetName: String = "原图"

    // 粒子与环境系统状态
    @State var particleStyle: String = ParticleMaterial.dust.rawValue
    @State var particleRate: Double = 0
    @State var particleLifetime: Double = 3
    @State var particleSize: Double = 4
    @State var particleGravity: Double = 9.8
    @State var particleTurbulence: Double = 2
    @State var particleSpin: Double = 0
    @State var particleThrust: Double = 0
    @State var particleAngle: Double = 0
    @State var particleSpread: Double = 360
    @State var particleFadeIn: Double = 10
    @State var particleFadeOut: Double = 30
    @State var particleColorStart = Color.white
    @State var particleColorEnd = LiquidGlassColors.primaryPink
    
    // 天气系统
    @State var weatherWind: Double = 0
    @State var weatherRain: Double = 0
    @State var weatherThunder: Double = 0
    @State var weatherSnow: Double = 0
    @State private var lightningFlash: Double = 0 

    @State var isShowingShaderEditor = false
    @State private var studioIntensity: Double = 0
    @State private var isExpertExpanded = false
    @State private var activeWeatherScene: LabWeatherScene = .dust
    @State private var activeParticleLayer: LabParticleLayer = .middle
    
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
        .overlay { chromeOverlay }
        .overlay(alignment: .bottomLeading) {
            DownloadProgressOverlay(downloadManager: downloadManager)
        }
        .overlay { toastOverlay }
        .preferredColorScheme(.dark)
        .task(id: previewCacheTaskID) {
            await viewModel.prepareFullResolutionPreview(for: wallpaper)
        }
        .onAppear {
            viewModel.syncFavoriteDisplayState(for: wallpaper, in: modelContext)
            loadSavedStudioPreset()
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
                        .frame(maxWidth: 720, alignment: .leading)
                        .padding(.leading, 80)
                        .padding(.top, 80)

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

            if isStudioActive {
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

    private var fullscreenCanvas: some View {
        DetailPreviewCanvas(
            wallpaper: wallpaper,
            contentURL: wallpaperContentURL,
            posterURL: wallpaperPosterURL,
            isStudioActive: isStudioActive,
            exposure: exposure,
            contrast: contrast,
            saturation: saturation,
            hue: hue,
            blur: blur,
            grain: grain,
            vignette: vignette,
            grayscale: grayscale,
            invert: invert,
            highlights: highlights,
            shadows: shadows,
            weatherWind: weatherWind,
            weatherRain: weatherRain,
            weatherThunder: weatherThunder,
            weatherSnow: weatherSnow,
            lightningFlash: $lightningFlash,
            particleStyle: particleStyle,
            particleRate: particleRate,
            particleLifetime: particleLifetime,
            particleSize: particleSize,
            particleGravity: particleGravity,
            particleTurbulence: particleTurbulence,
            particleSpin: particleSpin,
            particleThrust: particleThrust,
            particleAngle: particleAngle,
            particleSpread: particleSpread,
            particleFadeIn: particleFadeIn,
            particleFadeOut: particleFadeOut,
            particleColorStart: particleColorStart,
            particleColorEnd: particleColorEnd
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
            }
            if newWallpaper.type == .video, let videoURL = WallpaperDetailViewModel.url(from: newWallpaper.filePath) {
                PreviewResourcePipeline.shared.preloadVideo(url: videoURL)
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
            Text("精选画廊").font(.system(size: 12, weight: .black)).kerning(5).foregroundStyle(LiquidGlassColors.primaryPink)
            Text(wallpaper.name).artisanTitleStyle(size: 48, kerning: 1).shadow(color: .black.opacity(0.5), radius: 20)

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

    private func metadataTag(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 10))
            Text(text).font(.system(size: 10, weight: .bold))
        }
        .foregroundStyle(.white.opacity(0.6))
        .padding(.horizontal, 12).padding(.vertical, 6)
        .background(Capsule().fill(Color.white.opacity(0.1)))
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
            isApplying: isApplying,
            isStudioActive: isStudioActive,
            isDownloading: viewModel.isDownloading,
            onFavorite: toggleFavorite,
            onApply: { Task { await applyWallpaper() } },
            onToggleStudio: {
                withAnimation(.gallerySpring) {
                    isStudioActive.toggle()
                    if !isStudioActive { NSColorPanel.shared.orderOut(nil) }
                }
            },
            onDownload: { Task { await downloadWallpaper() } }
        )
    }

    private var artisanStudioHUD: some View {
        DetailStudioPanel(
            isStudioActive: $isStudioActive,
            studioTab: $studioTab,
            exposure: $exposure,
            contrast: $contrast,
            saturation: $saturation,
            hue: $hue,
            blur: $blur,
            grain: $grain,
            vignette: $vignette,
            grayscale: $grayscale,
            invert: $invert,
            highlights: $highlights,
            shadows: $shadows,
            dispersion: $dispersion,
            currentPresetName: $currentPresetName,
            particleStyle: $particleStyle,
            particleRate: $particleRate,
            particleLifetime: $particleLifetime,
            particleSize: $particleSize,
            particleGravity: $particleGravity,
            particleTurbulence: $particleTurbulence,
            particleSpin: $particleSpin,
            particleThrust: $particleThrust,
            particleAngle: $particleAngle,
            particleSpread: $particleSpread,
            particleFadeIn: $particleFadeIn,
            particleFadeOut: $particleFadeOut,
            particleColorStart: $particleColorStart,
            particleColorEnd: $particleColorEnd,
            weatherWind: $weatherWind,
            weatherRain: $weatherRain,
            weatherThunder: $weatherThunder,
            weatherSnow: $weatherSnow,
            studioIntensity: $studioIntensity,
            isExpertExpanded: $isExpertExpanded,
            activeWeatherScene: $activeWeatherScene,
            activeParticleLayer: $activeParticleLayer,
            onApplySmartPreset: applySmartPreset,
            onApplyWeatherScene: applyWeatherScene,
            onApplyParticleLayer: applyParticleLayer,
            onApplyStudioIntensity: applyStudioIntensity,
            onReset: resetStudioState,
            onSave: applyCurrentPreset
        )
    }

    private func resetStudioState() {
        resetFilters()
        withAnimation(.gallerySpring) {
            studioIntensity = 0
            isExpertExpanded = false
            activeWeatherScene = .dust
            activeParticleLayer = .middle
            weatherWind = 0
            weatherRain = 0
            weatherThunder = 0
            weatherSnow = 0
        }
    }

    private func applySmartPreset(_ preset: BuiltInPreset) {
        applyPreset(preset)
        withAnimation(.easeInOut(duration: 0.22)) {
            switch preset {
            case .original:
                studioIntensity = 0
                weatherRain = 0
                weatherSnow = 0
                weatherThunder = 0
                particleRate = 0
                particleStyle = ParticleMaterial.dust.rawValue
            case .vivid:
                studioIntensity = 58
                particleStyle = ParticleMaterial.shard.rawValue
                particleRate = 72
                particleSize = 4
                particleGravity = 1.2
                particleTurbulence = 6
                activeWeatherScene = .dust
            case .warm:
                studioIntensity = 54
                activeWeatherScene = .fog
                particleStyle = ParticleMaterial.petal.rawValue
                particleRate = 42
                particleSize = 8
                particleGravity = 2.2
                particleTurbulence = 5
                weatherRain = 0
                weatherSnow = 0
            case .cool:
                studioIntensity = 48
                activeWeatherScene = .dust
                particleStyle = ParticleMaterial.mist.rawValue
                particleRate = 58
                particleSize = 3
                particleGravity = 0.7
                particleTurbulence = 5
                weatherRain = 0
                weatherSnow = 12
            case .noir:
                studioIntensity = 46
                activeWeatherScene = .dust
                particleStyle = ParticleMaterial.dust.rawValue
                particleRate = 48
                particleSize = 2.6
                particleGravity = 0.4
                weatherRain = 0
                weatherSnow = 0
            case .vintage:
                studioIntensity = 62
                activeWeatherScene = .dust
                particleStyle = ParticleMaterial.bokeh.rawValue
                particleRate = 86
                particleSize = 3.2
                particleGravity = 0.8
                particleTurbulence = 8
                weatherRain = 0
                weatherSnow = 0
            case .cinematic:
                studioIntensity = 66
                activeWeatherScene = .cyberRain
                particleStyle = ParticleMaterial.rain.rawValue
                particleRate = 68
                particleSize = 3.6
                particleGravity = 4
                particleTurbulence = 3
                weatherWind = 18
                weatherRain = 26
                weatherSnow = 0
            case .fade:
                studioIntensity = 40
                activeWeatherScene = .dust
                particleStyle = ParticleMaterial.glow.rawValue
                particleRate = 38
                particleSize = 3
                particleGravity = 0.4
                particleTurbulence = 3
                weatherRain = 0
                weatherSnow = 0
            }
        }
    }

    private func applyWeatherScene(_ scene: LabWeatherScene) {
        withAnimation(.easeInOut(duration: 0.22)) {
            activeWeatherScene = scene
            switch scene {
            case .dust:
                weatherWind = 8
                weatherRain = 0
                weatherSnow = 0
                weatherThunder = 0
                particleStyle = ParticleMaterial.dust.rawValue
                particleRate = max(44, studioIntensity * 1.1)
                particleLifetime = 5
                particleSize = 3
                particleGravity = 0.5
                particleTurbulence = 5
                particleColorStart = .white
                particleColorEnd = LiquidGlassColors.champagne
            case .fog:
                weatherWind = 6
                weatherRain = 0
                weatherSnow = 0
                weatherThunder = 0
                particleStyle = ParticleMaterial.mist.rawValue
                particleRate = max(32, studioIntensity * 0.75)
                particleLifetime = 8
                particleSize = 7
                particleGravity = 0.15
                particleTurbulence = 4
                particleColorStart = .white
                particleColorEnd = LiquidGlassColors.champagne
            case .snow:
                weatherWind = -8
                weatherRain = 0
                weatherSnow = max(22, studioIntensity * 0.7)
                weatherThunder = 0
                particleStyle = ParticleMaterial.snow.rawValue
                particleRate = max(32, studioIntensity * 0.9)
                particleLifetime = 7
                particleSize = 5
                particleGravity = 1.4
                particleTurbulence = 4
                particleColorStart = .white
                particleColorEnd = LiquidGlassColors.tertiaryBlue
            case .cyberRain:
                weatherWind = 18
                weatherRain = max(24, studioIntensity * 0.8)
                weatherSnow = 0
                weatherThunder = min(42, studioIntensity * 0.28)
                particleStyle = ParticleMaterial.rain.rawValue
                particleRate = max(54, studioIntensity * 1.25)
                particleLifetime = 2.8
                particleSize = 3.6
                particleGravity = 5.5
                particleTurbulence = 3
                particleColorStart = LiquidGlassColors.tertiaryBlue
                particleColorEnd = LiquidGlassColors.primaryViolet
            }
        }
    }

    private func applyParticleLayer(_ layer: LabParticleLayer) {
        withAnimation(.easeInOut(duration: 0.22)) {
            activeParticleLayer = layer
            switch layer {
            case .background:
                particleRate = max(42, studioIntensity * 1.15)
                particleLifetime = 7
                particleSize = 2.4
                particleGravity = 0.2
                particleTurbulence = 3.5
                particleSpin = 1.5
                particleFadeIn = 18
                particleFadeOut = 52
            case .middle:
                particleRate = max(56, studioIntensity * 1.25)
                particleLifetime = 5
                particleSize = 4
                particleGravity = 1.0
                particleTurbulence = 5
                particleSpin = 3
                particleFadeIn = 12
                particleFadeOut = 36
            case .foreground:
                particleRate = max(18, studioIntensity * 0.42)
                particleLifetime = 3.2
                particleSize = 9
                particleGravity = 2.5
                particleTurbulence = 8
                particleSpin = 7
                particleFadeIn = 6
                particleFadeOut = 24
            case .blend:
                grain = min(28, max(grain, studioIntensity * 0.22))
                vignette = min(62, max(vignette, studioIntensity * 0.52))
                particleFadeIn = 22
                particleFadeOut = 64
                particleTurbulence = 4
            }
        }
    }

    private func applyStudioIntensity(_ value: Double) {
        let normalized = value / 100.0
        withAnimation(.easeInOut(duration: 0.12)) {
            particleRate = max(1, normalized * 150)
            vignette = min(70, normalized * 56)
            grain = min(38, normalized * 24)
            switch activeWeatherScene {
            case .dust, .fog:
                weatherRain = 0
                weatherSnow = 0
            case .snow:
                weatherSnow = normalized * 88
                weatherRain = 0
            case .cyberRain:
                weatherRain = normalized * 82
                weatherThunder = normalized * 32
                weatherSnow = 0
            }
        }
    }

    private func loadSavedStudioPreset() {
        guard let pass = wallpaper.shaderPreset?.passes.first(where: { $0.name == "实验室实时调校" }) else { return }
        currentPresetName = wallpaper.shaderPreset?.name ?? currentPresetName
        exposure = pass.double("exposure", default: exposure)
        contrast = pass.double("contrast", default: contrast)
        saturation = pass.double("saturation", default: saturation)
        hue = pass.double("hue", default: hue)
        blur = pass.double("blur", default: blur)
        grain = pass.double("grain", default: grain)
        vignette = pass.double("vignette", default: vignette)
        grayscale = pass.double("grayscale", default: grayscale)
        invert = pass.double("invert", default: invert)
        highlights = pass.double("highlights", default: highlights)
        shadows = pass.double("shadows", default: shadows)
        dispersion = pass.double("dispersion", default: dispersion)
        weatherWind = pass.double("weatherWind", default: weatherWind)
        weatherRain = pass.double("weatherRain", default: weatherRain)
        weatherThunder = pass.double("weatherThunder", default: weatherThunder)
        weatherSnow = pass.double("weatherSnow", default: weatherSnow)
        activeWeatherScene = LabWeatherScene.allCases[safe: pass.int("activeWeatherScene", default: LabWeatherScene.allCases.firstIndex(of: activeWeatherScene) ?? 0)] ?? activeWeatherScene
        activeParticleLayer = LabParticleLayer.allCases[safe: pass.int("activeParticleLayer", default: LabParticleLayer.allCases.firstIndex(of: activeParticleLayer) ?? 0)] ?? activeParticleLayer
        let currentMaterialIndex = labParticleMaterials.firstIndex(of: ParticleMaterial(style: particleStyle)) ?? 0
        if let material = labParticleMaterials[safe: pass.int("particleMaterial", default: -1)] {
            particleStyle = material.rawValue
        } else if let legacyMaterial = ParticleMaterial.legacyMaterial(for: pass.int("particleStyle", default: -1)) {
            particleStyle = legacyMaterial.rawValue
        } else {
            particleStyle = labParticleMaterials[safe: currentMaterialIndex]?.rawValue ?? particleStyle
        }
        particleRate = pass.double("particleRate", default: particleRate)
        particleLifetime = pass.double("particleLifetime", default: particleLifetime)
        particleSize = pass.double("particleSize", default: particleSize)
        particleGravity = pass.double("particleGravity", default: particleGravity)
        particleTurbulence = pass.double("particleTurbulence", default: particleTurbulence)
        particleSpin = pass.double("particleSpin", default: particleSpin)
        particleThrust = pass.double("particleThrust", default: particleThrust)
        particleAngle = pass.double("particleAngle", default: particleAngle)
        particleSpread = pass.double("particleSpread", default: particleSpread)
        particleFadeIn = pass.double("particleFadeIn", default: particleFadeIn)
        particleFadeOut = pass.double("particleFadeOut", default: particleFadeOut)
    }

    private var currentRenderEffects: WallpaperRenderEffects {
        WallpaperRenderEffects(
            name: currentPresetName,
            exposure: exposure,
            contrast: contrast,
            saturation: saturation,
            hue: hue,
            blur: blur,
            grain: grain,
            vignette: vignette,
            grayscale: grayscale,
            invert: invert,
            highlights: highlights,
            shadows: shadows,
            dispersion: dispersion,
            weatherWind: weatherWind,
            weatherRain: weatherRain,
            weatherThunder: weatherThunder,
            weatherSnow: weatherSnow,
            particleStyle: ParticleMaterial(style: particleStyle).rawValue,
            particleRate: particleRate,
            particleLifetime: particleLifetime,
            particleSize: particleSize,
            particleGravity: particleGravity,
            particleTurbulence: particleTurbulence,
            particleSpin: particleSpin,
            particleThrust: particleThrust,
            particleAngle: particleAngle,
            particleSpread: particleSpread,
            particleFadeIn: particleFadeIn,
            particleFadeOut: particleFadeOut
        )
    }

    private var currentShaderPasses: [ShaderPassConfig] {
        let effects = currentRenderEffects
        return [
            ShaderPassConfig(
                id: UUID(),
                type: .postprocess,
                name: "实验室实时调校",
                enabled: true,
                parameters: [
                    "exposure": .float(Float(effects.exposure)),
                    "contrast": .float(Float(effects.contrast)),
                    "saturation": .float(Float(effects.saturation)),
                    "hue": .float(Float(effects.hue)),
                    "blur": .float(Float(effects.blur)),
                    "grain": .float(Float(effects.grain)),
                    "vignette": .float(Float(effects.vignette)),
                    "grayscale": .float(Float(effects.grayscale)),
                    "invert": .float(Float(effects.invert)),
                    "highlights": .float(Float(effects.highlights)),
                    "shadows": .float(Float(effects.shadows)),
                    "dispersion": .float(Float(effects.dispersion)),
                    "weatherWind": .float(Float(effects.weatherWind)),
                    "weatherRain": .float(Float(effects.weatherRain)),
                    "weatherThunder": .float(Float(effects.weatherThunder)),
                    "weatherSnow": .float(Float(effects.weatherSnow)),
                    "activeWeatherScene": .int(LabWeatherScene.allCases.firstIndex(of: activeWeatherScene) ?? 0),
                    "activeParticleLayer": .int(LabParticleLayer.allCases.firstIndex(of: activeParticleLayer) ?? 0),
                    "particleMaterial": .int(labParticleMaterials.firstIndex(of: ParticleMaterial(style: effects.particleStyle)) ?? 0),
                    "particleRate": .float(Float(effects.particleRate)),
                    "particleLifetime": .float(Float(effects.particleLifetime)),
                    "particleSize": .float(Float(effects.particleSize)),
                    "particleGravity": .float(Float(effects.particleGravity)),
                    "particleTurbulence": .float(Float(effects.particleTurbulence)),
                    "particleSpin": .float(Float(effects.particleSpin)),
                    "particleThrust": .float(Float(effects.particleThrust)),
                    "particleAngle": .float(Float(effects.particleAngle)),
                    "particleSpread": .float(Float(effects.particleSpread)),
                    "particleFadeIn": .float(Float(effects.particleFadeIn)),
                    "particleFadeOut": .float(Float(effects.particleFadeOut))
                ]
            )
        ]
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
        isApplying = true; defer { isApplying = false }
        do {
            let effects = currentRenderEffects
            let localWallpaper = try await ensureLocalWallpaperForApply()
            if localWallpaper.type == .video {
                let videoURL = URL(fileURLWithPath: localWallpaper.filePath)
                try await RenderPipeline.shared.setWallpaper(url: videoURL, wallpaperId: localWallpaper.id, effects: effects)
            } else {
                let imageURL = URL(fileURLWithPath: localWallpaper.filePath)
                let renderedURL = try WallpaperRenderEffectRenderer.renderImage(sourceURL: imageURL, effects: effects)
                if effects.hasDynamicEnvironment {
                    try await RenderPipeline.shared.setImageWallpaper(url: renderedURL, wallpaperId: localWallpaper.id, effects: effects)
                } else {
                    RenderPipeline.shared.cleanup()
                    try await MainActor.run { try WallpaperSetter.shared.setWallpaper(imageURL: renderedURL) }
                }
            }
            if effects.hasDynamicEnvironment {
                showToastMessage("已应用基础调校，动态天气/粒子已保存")
            } else {
                showToastMessage("设置成功")
            }
        } catch { showToastMessage("失败: \(error.localizedDescription)") }
    }

    private func ensureLocalWallpaperForApply() async throws -> Wallpaper {
        if !isRemotePath(wallpaper.filePath), FileManager.default.fileExists(atPath: wallpaper.filePath) {
            return wallpaper
        }

        if let remoteId = wallpaper.remoteId,
           let downloaded = DownloadManager.shared.isAlreadyDownloaded(remoteId: remoteId, context: modelContext) {
            wallpaper = downloaded
            return downloaded
        }

        guard let remoteURL = remoteDownloadURLForApply else {
            throw NSError(domain: "PlumWallPaper", code: 1, userInfo: [NSLocalizedDescriptionKey: "找不到可下载的远程地址"])
        }

        let downloaded = try await DownloadManager.shared.downloadWallpaper(
            item: .local(wallpaper),
            quality: wallpaper.resolution ?? "Original",
            downloadURL: remoteURL,
            context: modelContext
        )
        wallpaper = downloaded
        onDownload?(downloaded)
        return downloaded
    }

    private var remoteDownloadURLForApply: URL? {
        let preferredPath = highQualityVideoPathForApply ?? wallpaper.filePath
        guard isRemotePath(preferredPath) else { return nil }
        return URL(string: preferredPath)
    }

    private var highQualityVideoPathForApply: String? {
        guard wallpaper.type == .video,
              let quality = wallpaper.downloadQuality,
              isRemotePath(quality)
        else { return nil }
        return quality
    }

    private func isRemotePath(_ path: String) -> Bool {
        guard let url = URL(string: path), let scheme = url.scheme?.lowercased() else { return false }
        return scheme == "http" || scheme == "https"
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
            wallpaper.shaderPreset = ShaderPreset(name: currentPresetName)
        } else {
            wallpaper.shaderPreset?.name = currentPresetName
        }
        wallpaper.shaderPreset?.passes = currentShaderPasses
        try? modelContext.save()
        showToastMessage("已保存实验室参数")
    }

    private func showToastMessage(_ message: String) {
        toastMessage = message; showToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { withAnimation { showToast = false } }
    }
}

private extension ShaderPassConfig {
    func double(_ key: String, default defaultValue: Double) -> Double {
        guard let value = parameters[key] else { return defaultValue }
        if case .float(let number) = value {
            return Double(number)
        }
        if case .int(let number) = value {
            return Double(number)
        }
        return defaultValue
    }

    func int(_ key: String, default defaultValue: Int) -> Int {
        guard let value = parameters[key] else { return defaultValue }
        if case .int(let number) = value {
            return number
        }
        if case .float(let number) = value {
            return Int(number)
        }
        return defaultValue
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
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
    var exposure: Double { [.original:100, .vivid:110, .warm:105, .cool:95, .noir:100, .vintage:90, .cinematic:85, .fade:80][self] ?? 100 }
    var contrast: Double { [.original:100, .vivid:120, .warm:105, .cool:105, .noir:130, .vintage:90, .cinematic:110, .fade:70][self] ?? 100 }
    var saturation: Double { [.original:100, .vivid:150, .warm:120, .cool:90, .noir:0, .vintage:70, .cinematic:80, .fade:50][self] ?? 100 }
    var hue: Double { [.original:0, .vivid:0, .warm:15, .cool:-15, .noir:0, .vintage:20, .cinematic:-10, .fade:0][self] ?? 0 }
    var blur: Double { [.original:0, .vivid:0, .warm:0, .cool:0, .noir:0, .vintage:1, .cinematic:0.5, .fade:2][self] ?? 0 }
    var grain: Double { [.original:0, .vivid:0, .warm:5, .cool:0, .noir:20, .vintage:40, .cinematic:15, .fade:10][self] ?? 0 }
    var vignette: Double { [.original:0, .vivid:0, .warm:10, .cool:15, .noir:30, .vintage:40, .cinematic:50, .fade:20][self] ?? 0 }
    var grayscale: Double { [.original:0, .vivid:0, .warm:0, .cool:0, .noir:100, .vintage:0, .cinematic:0, .fade:30][self] ?? 0 }
    var invert: Double { 0 }
}
