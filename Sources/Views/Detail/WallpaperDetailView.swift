import SwiftUI
import AppKit
import AVFoundation

// MARK: - Artisan Exhibition Hall (Scheme C: Artisan Gallery)
// 沉浸式壁纸鉴赏厅，UI 仅在鼠标触碰功能区时如雾般浮现。

private enum LabTab: Int, CaseIterable, Identifiable {
    case smart, color, effects, weather, particles

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .smart: return "预设"
        case .color: return "色彩"
        case .effects: return "特效"
        case .weather: return "环境"
        case .particles: return "粒子"
        }
    }

    var headerTitle: String {
        switch self {
        case .smart: return "快速调校"
        case .color: return "色彩调校"
        case .effects: return "视觉特效"
        case .weather: return "环境层"
        case .particles: return "粒子层"
        }
    }

    var subtitle: String {
        switch self {
        case .smart: return "总强度 + 风格预设"
        case .color: return "曝光、反差、色调即时反馈"
        case .effects: return "颗粒、暗角、色散和质感"
        case .weather: return "风、雾、雨、雪与雷电"
        case .particles: return "前中后三层环境粒子"
        }
    }

    var icon: String {
        switch self {
        case .smart: return "sparkles"
        case .color: return "camera.filters"
        case .effects: return "wand.and.stars"
        case .weather: return "cloud.sun"
        case .particles: return "circle.hexagongrid"
        }
    }
}

private enum LabWeatherScene: String, CaseIterable, Identifiable {
    case dust, fog, snow, cyberRain

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dust: return "微尘"
        case .fog: return "薄雾"
        case .snow: return "薄雪"
        case .cyberRain: return "霓光雨"
        }
    }

    var detail: String {
        switch self {
        case .dust: return "低速漂浮，适合漫画/插画"
        case .fog: return "低透明雾层，柔化远景"
        case .snow: return "三层景深，低透明混合"
        case .cyberRain: return "斜向雨丝，响应风向"
        }
    }

    var icon: String {
        switch self {
        case .dust: return "aqi.medium"
        case .fog: return "cloud.fog.fill"
        case .snow: return "snowflake"
        case .cyberRain: return "cloud.rain.fill"
        }
    }
}

private enum LabParticleLayer: String, CaseIterable, Identifiable {
    case background, middle, foreground, blend

    var id: String { rawValue }

    var title: String {
        switch self {
        case .background: return "背景层"
        case .middle: return "中景层"
        case .foreground: return "前景层"
        case .blend: return "融合规则"
        }
    }

    var detail: String {
        switch self {
        case .background: return "小、慢、模糊"
        case .middle: return "跟随画面色调"
        case .foreground: return "少量大颗粒"
        case .blend: return "亮部降透明"
        }
    }
}

private let labParticleMaterials = ParticleMaterial.allCases

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
    @State private var isDownloading = false
    @State private var toastMessage: String?
    @State private var showToast = false
    @State private var isNavigatingWallpaper = false
    @StateObject private var downloadManager = DownloadManager.shared

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
        .onAppear {
            if wallpaper.type == .video, let videoURL = wallpaperContentURL {
                VideoPreloader.shared.preload(url: videoURL)
            }
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
        ZStack {
            ArtisanBackgroundLayer(
                wallpaper: wallpaper,
                contentURL: wallpaperContentURL,
                posterURL: wallpaperPosterURL,
                blur: blur,
                grayscale: grayscale,
                contrast: contrast,
                saturation: saturation,
                exposure: exposure,
                hue: hue,
                highlights: highlights,
                shadows: shadows,
                invert: invert,
                grain: grain,
                vignette: vignette
            )

            Group {
                if weatherThunder > 0 {
                    ArtisanLightningLayer(frequency: weatherThunder, flash: $lightningFlash)
                }
                if weatherSnow > 0 {
                    ArtisanSnowLayer(intensity: weatherSnow, wind: weatherWind)
                }
                if weatherRain > 0 {
                    ArtisanRainLayer(intensity: weatherRain, wind: weatherWind)
                }
            }

            if isStudioActive && particleRate > 0 {
                ParticleOverlay(
                    style: particleStyle,
                    rate: particleRate,
                    lifetime: particleLifetime,
                    size: particleSize,
                    gravity: particleGravity,
                    turbulence: particleTurbulence,
                    spin: particleSpin,
                    thrust: particleThrust,
                    angle: particleAngle,
                    spread: particleSpread,
                    fadeIn: particleFadeIn,
                    fadeOut: particleFadeOut,
                    wind: weatherWind,
                    isRainMode: false,
                    colorStart: particleColorStart,
                    colorEnd: particleColorEnd
                )
                .drawingGroup()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .ignoresSafeArea()
        .id("canvas-\(wallpaper.id)")
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
            withAnimation(.galleryEase) { self.wallpaper = newWallpaper }
            if newWallpaper.type == .video, let videoURL = url(from: newWallpaper.filePath) {
                VideoPreloader.shared.preload(url: videoURL)
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
        .background(Capsule().fill(Color.white.opacity(0.1)))
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
        HStack(spacing: 24) {
            actionCircleButton(icon: wallpaper.isFavorite ? "heart.fill" : "heart", color: wallpaper.isFavorite ? LiquidGlassColors.primaryPink : .white.opacity(0.6)) {
                wallpaper.isFavorite.toggle()
                try? modelContext.save()
                onFavorite?(wallpaper)
            }
            Button(action: { Task { await applyWallpaper() } }) {
                HStack(spacing: 16) {
                    if isApplying { CustomProgressView(tint: .white, scale: 0.8) }
                    else { Text("设为壁纸").font(.system(size: 14, weight: .bold)).kerning(2) }
                }
                .padding(.horizontal, 60).frame(height: 52)
                .background(LiquidGlassColors.primaryPink).clipShape(Capsule()).foregroundStyle(.black)
                .artisanShadow(color: LiquidGlassColors.primaryPink.opacity(0.3), radius: 20)
            }.buttonStyle(.plain).disabled(isApplying)

            Button(action: { withAnimation(.gallerySpring) { 
                isStudioActive.toggle()
                if !isStudioActive { NSColorPanel.shared.orderOut(nil) }
            } }) {
                VStack(spacing: 4) {
                    Image(systemName: "camera.aperture").font(.system(size: 18))
                    Text("实验室").font(.system(size: 10, weight: .bold))
                }
                .foregroundStyle(isStudioActive ? LiquidGlassColors.primaryPink : .white.opacity(0.6))
                .frame(width: 52, height: 52).background(Circle().fill(Color.white.opacity(0.05)))
                .overlay(Circle().stroke(isStudioActive ? LiquidGlassColors.primaryPink.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1))
            }.buttonStyle(.plain)

            actionCircleButton(icon: "arrow.down.to.line.compact", color: .white.opacity(0.6)) { Task { await downloadWallpaper() } }.disabled(isDownloading)
        }
        .padding(12).background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 0.5))
        .artisanShadow(color: .black.opacity(0.2), radius: 30)
    }

    private var artisanStudioHUD: some View {
        HStack(spacing: 0) {
            studioRail
                .frame(width: 112)
                .background(Color.white.opacity(0.018))

            Divider()
                .frame(width: 1)
                .opacity(0.08)

            VStack(alignment: .leading, spacing: 0) {
                studioHeader

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        studioWorkspace
                        if isExpertExpanded { expertParameterShelf }
                    }
                    .padding(22)
                }

                studioActionBar
            }
            .frame(width: 430)
        }
        .frame(width: 544, height: 570)
        .background(LiquidGlassColors.deepBackground.opacity(0.74))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
        )
        .artisanShadow(color: .black.opacity(0.44), radius: 64, y: 26)
    }

    private var studioRail: some View {
        VStack(spacing: 12) {
            Text("实验室")
                .font(.system(size: 11, weight: .black))
                .kerning(1.6)
                .foregroundStyle(LiquidGlassColors.primaryPink)
                .padding(.top, 24)
                .padding(.bottom, 10)

            ForEach(LabTab.allCases) { tab in
                studioRailButton(tab)
            }

            Spacer(minLength: 0)
        }
    }

    private func studioRailButton(_ tab: LabTab) -> some View {
        let isSelected = selectedLabTab == tab
        return Button {
            withAnimation(.gallerySpring) { studioTab = tab.rawValue }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: tab.icon)
                    .font(.system(size: 16, weight: .light))
                    .frame(width: 34, height: 30)
                Text(tab.title)
                    .font(.system(size: 11, weight: .black))
                    .kerning(0.8)
            }
            .foregroundStyle(isSelected ? LiquidGlassColors.primaryPink : .white.opacity(0.28))
            .frame(width: 84, height: 70)
            .background {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(isSelected ? Color.white.opacity(0.055) : Color.clear)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(isSelected ? LiquidGlassColors.primaryPink.opacity(0.28) : Color.clear, lineWidth: 0.5)
            }
        }
        .buttonStyle(.plain)
    }

    private var studioHeader: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("实时调校")
                    .font(.system(size: 10, weight: .black))
                    .kerning(1.5)
                    .foregroundStyle(.white.opacity(0.24))
                Text(selectedLabTab.headerTitle)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.88))
                Text(selectedLabTab.subtitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.36))
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            Button {
                withAnimation(.gallerySpring) {
                    isStudioActive = false
                    NSColorPanel.shared.orderOut(nil)
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.36))
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(Color.white.opacity(0.045)))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 20)
        .border(width: 0.5, edges: [.bottom], color: .white.opacity(0.06))
    }

    private var currentTabLabel: String {
        selectedLabTab.headerTitle
    }

    private var selectedLabTab: LabTab {
        LabTab(rawValue: studioTab) ?? .smart
    }

    private var compactDialColumns: [GridItem] {
        [
            GridItem(.fixed(180), spacing: 20),
            GridItem(.fixed(180), spacing: 20)
        ]
    }

    private var intensityBinding: Binding<Double> {
        Binding(
            get: { studioIntensity },
            set: { newValue in
                studioIntensity = newValue
                applyStudioIntensity(newValue)
            }
        )
    }

    @ViewBuilder
    private var studioWorkspace: some View {
        switch selectedLabTab {
        case .smart:
            smartWorkspace
        case .color:
            colorWorkspace
        case .effects:
            effectsWorkspace
        case .weather:
            weatherWorkspace
        case .particles:
            particlesWorkspace
        }
    }

    @ViewBuilder
    private var smartWorkspace: some View {
        VStack(alignment: .leading, spacing: 20) {
            intensityControl

            sectionKicker("风格预设")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach([BuiltInPreset.cinematic, .warm, .cool, .vintage, .fade, .original]) { preset in
                    lookButton(preset)
                }
            }
        }
    }

    private var colorWorkspace: some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionKicker("色彩调校")
            LazyVGrid(columns: compactDialColumns, alignment: .leading, spacing: 24) {
                ArtisanRulerDial(label: "曝光", value: $exposure, range: 0...200, unit: "ev")
                ArtisanRulerDial(label: "对比度", value: $contrast, range: 50...150, unit: "%")
                ArtisanRulerDial(label: "饱和度", value: $saturation, range: 0...200, unit: "%")
                ArtisanRulerDial(label: "高光", value: $highlights, range: 0...200, unit: "%")
                ArtisanRulerDial(label: "阴影", value: $shadows, range: 0...200, unit: "%")
                ArtisanRulerDial(label: "色相", value: $hue, range: -180...180, unit: "°")
            }
        }
    }

    private var effectsWorkspace: some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionKicker("视觉特效")
            LazyVGrid(columns: compactDialColumns, alignment: .leading, spacing: 24) {
                ArtisanRulerDial(label: "模糊", value: $blur, range: 0...40, unit: "px")
                ArtisanRulerDial(label: "颗粒", value: $grain, range: 0...100, unit: "%")
                ArtisanRulerDial(label: "暗角", value: $vignette, range: 0...100, unit: "%")
                ArtisanRulerDial(label: "黑白", value: $grayscale, range: 0...100, unit: "%")
                ArtisanRulerDial(label: "反相", value: $invert, range: 0...100, unit: "%")
                ArtisanRulerDial(label: "色散", value: $dispersion, range: 0...20, unit: "px")
            }
        }
    }

    private var weatherWorkspace: some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionKicker("环境层")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(LabWeatherScene.allCases) { scene in
                    weatherSceneCard(scene)
                }
            }

            LazyVGrid(columns: compactDialColumns, alignment: .leading, spacing: 24) {
                ArtisanRulerDial(label: "全局风力", value: $weatherWind, range: -50...50, unit: "km/h")
                ArtisanRulerDial(label: "降雨强度", value: $weatherRain, range: 0...100, unit: "%")
                ArtisanRulerDial(label: "降雪密度", value: $weatherSnow, range: 0...100, unit: "%")
                ArtisanRulerDial(label: "雷电频率", value: $weatherThunder, range: 0...100, unit: "%")
            }
        }
    }

    private var particlesWorkspace: some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionKicker("粒子系统")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(LabParticleLayer.allCases) { layer in
                    layerCard(layer)
                }
            }

            particleStylePicker

            HStack(spacing: 18) {
                colorPreview(label: "起始色", color: $particleColorStart)
                colorPreview(label: "结束色", color: $particleColorEnd)
            }

            LazyVGrid(columns: compactDialColumns, alignment: .leading, spacing: 24) {
                ArtisanRulerDial(label: "速率", value: $particleRate, range: 1...300, unit: "p/s")
                ArtisanRulerDial(label: "寿命", value: $particleLifetime, range: 0.1...10, unit: "s")
                ArtisanRulerDial(label: "尺寸", value: $particleSize, range: 1...40, unit: "px")
                ArtisanRulerDial(label: "扰动", value: $particleTurbulence, range: 0...20, unit: "px")
                ArtisanRulerDial(label: "自旋", value: $particleSpin, range: 0...20, unit: "deg")
                ArtisanRulerDial(label: "重力", value: $particleGravity, range: -20...20, unit: "m/s²")
            }
        }
    }

    private var intensityControl: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("总强度")
                    .font(.system(size: 10, weight: .black))
                    .kerning(1.2)
                    .foregroundStyle(.white.opacity(0.24))
                Spacer()
                Text("\(Int(studioIntensity))")
                    .font(.system(size: 17, weight: .semibold, design: .monospaced))
                    .foregroundStyle(LiquidGlassColors.primaryPink.opacity(0.82))
            }

            Slider(value: intensityBinding, in: 0...100)
                .tint(LiquidGlassColors.primaryPink)
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.white.opacity(0.035)))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.white.opacity(0.08), lineWidth: 0.5))
    }

    private var expertParameterShelf: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionKicker("专家参数")
            LazyVGrid(columns: compactDialColumns, alignment: .leading, spacing: 20) {
                ArtisanRulerDial(label: "推力", value: $particleThrust, range: 0...50, unit: "pow")
                ArtisanRulerDial(label: "角度", value: $particleAngle, range: -180...180, unit: "°")
                ArtisanRulerDial(label: "扩散", value: $particleSpread, range: 0...360, unit: "°")
                ArtisanRulerDial(label: "渐显", value: $particleFadeIn, range: 0...100, unit: "%")
                ArtisanRulerDial(label: "渐隐", value: $particleFadeOut, range: 0...100, unit: "%")
            }
        }
        .padding(.top, 2)
    }

    private var studioActionBar: some View {
        HStack(spacing: 10) {
            Button(action: { resetStudioState() }) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white.opacity(0.32))
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(Color.white.opacity(0.04)))
            }
            .buttonStyle(.plain)

            Button {
                withAnimation(.gallerySpring) { isExpertExpanded.toggle() }
            } label: {
                Text(isExpertExpanded ? "收起专家参数" : "专家参数")
                    .font(.system(size: 13, weight: .black))
                    .kerning(0.8)
                    .foregroundStyle(isExpertExpanded ? LiquidGlassColors.primaryPink : .white.opacity(0.45))
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(Capsule().fill(Color.white.opacity(isExpertExpanded ? 0.07 : 0.035)))
                    .overlay(Capsule().stroke(isExpertExpanded ? LiquidGlassColors.primaryPink.opacity(0.28) : Color.white.opacity(0.08), lineWidth: 0.5))
            }
            .buttonStyle(.plain)

            Button(action: { applyCurrentPreset() }) {
                Image(systemName: "checkmark")
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(.black)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(LiquidGlassColors.primaryPink))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 16)
        .border(width: 0.5, edges: [.top], color: .white.opacity(0.06))
    }

    private func sectionKicker(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .black))
            .kerning(1.3)
            .foregroundStyle(.white.opacity(0.24))
    }

    private func lookButton(_ preset: BuiltInPreset) -> some View {
        let isActive = currentPresetName == preset.name
        return Button {
            applySmartPreset(preset)
        } label: {
            Text(preset.name)
                .font(.system(size: 13, weight: .bold))
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(isActive ? LiquidGlassColors.primaryPink.opacity(0.14) : Color.white.opacity(0.035))
                .foregroundStyle(isActive ? LiquidGlassColors.primaryPink : .white.opacity(0.45))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(isActive ? LiquidGlassColors.primaryPink.opacity(0.35) : Color.white.opacity(0.08), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }

    private func weatherSceneCard(_ scene: LabWeatherScene) -> some View {
        let isActive = activeWeatherScene == scene
        return Button {
            applyWeatherScene(scene)
        } label: {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Image(systemName: scene.icon)
                        .font(.system(size: 14, weight: .semibold))
                    Text(scene.title)
                        .font(.system(size: 14, weight: .bold))
                }
                Text(scene.detail)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(isActive ? 0.48 : 0.28))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(isActive ? LiquidGlassColors.primaryPink : .white.opacity(0.48))
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 88, alignment: .topLeading)
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(isActive ? LiquidGlassColors.primaryPink.opacity(0.09) : Color.white.opacity(0.035)))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(isActive ? LiquidGlassColors.primaryPink.opacity(0.3) : Color.white.opacity(0.08), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }

    private func layerCard(_ layer: LabParticleLayer) -> some View {
        let isActive = activeParticleLayer == layer
        return Button {
            applyParticleLayer(layer)
        } label: {
            VStack(alignment: .leading, spacing: 5) {
                Text(layer.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(isActive ? LiquidGlassColors.primaryPink : .white.opacity(0.68))
                Text(layer.detail)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(isActive ? 0.45 : 0.3))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(isActive ? LiquidGlassColors.primaryPink.opacity(0.09) : Color.white.opacity(0.035)))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(isActive ? LiquidGlassColors.primaryPink.opacity(0.3) : Color.white.opacity(0.075), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }

    private var particleStylePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionKicker("粒子材质")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(labParticleMaterials) { material in
                    particleMaterialCard(material)
                }
            }
        }
    }

    private func particleMaterialCard(_ material: ParticleMaterial) -> some View {
        let selectedMaterial = ParticleMaterial(style: particleStyle)
        let isActive = selectedMaterial == material
        return Button {
            withAnimation(.gallerySpring) { particleStyle = material.rawValue }
        } label: {
            HStack(spacing: 10) {
                ParticleMaterialSwatch(material: material, isActive: isActive)

                VStack(alignment: .leading, spacing: 3) {
                    Text(material.title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(isActive ? LiquidGlassColors.primaryPink : .white.opacity(0.68))
                    Text(material.detail)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(isActive ? 0.46 : 0.28))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 66)
            .padding(.horizontal, 12)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(isActive ? LiquidGlassColors.primaryPink.opacity(0.09) : Color.white.opacity(0.035)))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(isActive ? LiquidGlassColors.primaryPink.opacity(0.32) : Color.white.opacity(0.08), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }

    private func colorPreview(label: String, color: Binding<Color>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 10, weight: .black))
                .kerning(1.0)
                .foregroundStyle(.white.opacity(0.24))
            ColorPicker("", selection: color)
                .labelsHidden()
                .frame(width: 32, height: 32)
                .clipShape(Circle())
        }
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

    private func actionCircleButton(icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).font(.system(size: 18)).foregroundStyle(color)
                .frame(width: 52, height: 52).background(Circle().fill(Color.white.opacity(0.05)))
                .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 1))
        }.buttonStyle(.plain)
    }

    private func url(from path: String) -> URL? {
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        if let url = URL(string: trimmed), url.scheme != nil { return url }
        return URL(fileURLWithPath: trimmed)
    }

    private var wallpaperContentURL: URL? { url(from: wallpaper.filePath) }
    private var wallpaperPosterURL: URL? { wallpaper.thumbnailPath.flatMap { url(from: $0) } }

    private func applyWallpaper() async {
        isApplying = true; defer { isApplying = false }
        do {
            let effects = currentRenderEffects
            if wallpaper.type == .video {
                let path = highQualityVideoPathForApply ?? wallpaper.filePath
                let videoURL = URL(string: path)?.scheme != nil ? try await downloadTemp(URL(string: path)!) : URL(fileURLWithPath: path)
                try await RenderPipeline.shared.setWallpaper(url: videoURL, wallpaperId: wallpaper.id, effects: effects)
            } else {
                let imageURL = URL(string: wallpaper.filePath)?.scheme != nil ? try await downloadTemp(URL(string: wallpaper.filePath)!) : URL(fileURLWithPath: wallpaper.filePath)
                let renderedURL = try WallpaperRenderEffectRenderer.renderImage(sourceURL: imageURL, effects: effects)
                if effects.hasDynamicEnvironment {
                    try await RenderPipeline.shared.setImageWallpaper(url: renderedURL, wallpaperId: wallpaper.id, effects: effects)
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

    private func downloadTemp(_ url: URL) async throws -> URL {
        let local = FileManager.default.temporaryDirectory.appendingPathComponent("\(wallpaper.id.uuidString).\(url.pathExtension)")
        if !FileManager.default.fileExists(atPath: local.path) {
            let (data, _) = try await URLSession.shared.data(from: url)
            try data.write(to: local)
        }
        return local
    }

    private var highQualityVideoPathForApply: String? { (wallpaper.downloadQuality != nil && URL(string: wallpaper.downloadQuality!)?.scheme != nil) ? wallpaper.downloadQuality : nil }

    private func downloadWallpaper() async {
        guard let remoteURL = URL(string: wallpaper.filePath), remoteURL.scheme != nil else { showToastMessage("此壁纸已在本地"); return }
        if let remoteId = wallpaper.remoteId,
           DownloadManager.shared.isAlreadyDownloaded(remoteId: remoteId, context: modelContext) != nil {
            showToastMessage("此壁纸已在本地")
            return
        }

        isDownloading = true; defer { isDownloading = false }
        do {
            let downloaded = try await DownloadManager.shared.downloadWallpaper(
                item: .local(wallpaper),
                quality: wallpaper.resolution ?? "Original",
                downloadURL: remoteURL,
                context: modelContext
            )
            wallpaper = downloaded
            onDownload?(downloaded)
            showToastMessage("下载完成")
        } catch { showToastMessage("失败: \(error.localizedDescription)") }
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

private struct ParticleMaterialSwatch: View {
    let material: ParticleMaterial
    let isActive: Bool

    var body: some View {
        Canvas { context, size in
            drawMaterial(into: &context, size: size)
        }
        .frame(width: 38, height: 38)
        .background(Circle().fill(Color.white.opacity(isActive ? 0.07 : 0.035)))
        .overlay(Circle().stroke(isActive ? LiquidGlassColors.primaryPink.opacity(0.32) : Color.white.opacity(0.08), lineWidth: 0.5))
    }

    private func drawMaterial(into context: inout GraphicsContext, size: CGSize) {
        let accent = isActive ? LiquidGlassColors.primaryPink : Color.white.opacity(0.58)
        let center = CGPoint(x: size.width * 0.5, y: size.height * 0.5)

        switch material {
        case .dust:
            for i in 0..<9 {
                let seed = Double(i)
                let point = CGPoint(
                    x: size.width * (0.22 + 0.56 * (sin(seed * 31.7) * 0.5 + 0.5)),
                    y: size.height * (0.22 + 0.56 * (cos(seed * 17.4) * 0.5 + 0.5))
                )
                let radius = CGFloat(1.2 + (sin(seed * 9.1) * 0.5 + 0.5) * 1.8)
                context.fill(Path(ellipseIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)), with: .color(accent.opacity(0.22 + seed.truncatingRemainder(dividingBy: 3) * 0.08)))
            }
        case .glow:
            var glow = context
            glow.addFilter(.blur(radius: 5))
            glow.fill(Path(ellipseIn: CGRect(x: center.x - 12, y: center.y - 12, width: 24, height: 24)), with: .color(accent.opacity(0.42)))
            context.fill(Path(ellipseIn: CGRect(x: center.x - 3, y: center.y - 3, width: 6, height: 6)), with: .color(.white.opacity(0.72)))
        case .bokeh:
            for i in 0..<3 {
                let rect = CGRect(x: 6 + CGFloat(i) * 8, y: 8 + CGFloat(i % 2) * 10, width: 14 + CGFloat(i) * 3, height: 14 + CGFloat(i) * 3)
                var soft = context
                soft.addFilter(.blur(radius: 2.5))
                soft.fill(Path(ellipseIn: rect), with: .color(accent.opacity(0.16)))
                context.stroke(Path(ellipseIn: rect.insetBy(dx: 2, dy: 2)), with: .color(.white.opacity(0.16)), lineWidth: 0.7)
            }
        case .petal:
            for i in 0..<3 {
                var copy = context
                copy.translateBy(x: 11 + CGFloat(i) * 8, y: 14 + CGFloat(i % 2) * 6)
                copy.rotate(by: .degrees(Double(i) * 28 - 18))
                copy.fill(Self.petalPath(width: 15 + CGFloat(i) * 2, height: 7), with: .color(accent.opacity(0.52)))
            }
        case .shard:
            for i in 0..<4 {
                let x = CGFloat(8 + i * 7)
                var path = Path()
                path.move(to: CGPoint(x: x, y: 23 - CGFloat(i % 2) * 8))
                path.addLine(to: CGPoint(x: x + 7, y: 15 - CGFloat(i % 2) * 8))
                context.stroke(path, with: .color(accent.opacity(0.54)), lineWidth: 1.4)
            }
        case .ember:
            var glow = context
            glow.addFilter(.blur(radius: 4))
            glow.fill(Path(ellipseIn: CGRect(x: 9, y: 13, width: 20, height: 12)), with: .color(Color.orange.opacity(0.46)))
            context.fill(Path(ellipseIn: CGRect(x: 15, y: 17, width: 8, height: 5)), with: .color(Color.orange.opacity(0.9)))
        case .snow:
            for i in 0..<6 {
                let seed = Double(i)
                let radius = CGFloat(2.0 + (seed.truncatingRemainder(dividingBy: 3)))
                let point = CGPoint(x: 8 + CGFloat(i * 5), y: 11 + CGFloat(Int(seed * 7) % 17))
                context.fill(Path(ellipseIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)), with: .color(.white.opacity(0.5)))
            }
        case .rain:
            for i in 0..<5 {
                let x = CGFloat(8 + i * 6)
                var path = Path()
                path.move(to: CGPoint(x: x + 7, y: 7))
                path.addLine(to: CGPoint(x: x, y: 31))
                context.stroke(path, with: .color(accent.opacity(0.46)), lineWidth: 1.2)
            }
        case .mist:
            for i in 0..<3 {
                var mist = context
                mist.addFilter(.blur(radius: 5))
                let rect = CGRect(x: 5 + CGFloat(i) * 6, y: 13 + CGFloat(i % 2) * 3, width: 19, height: 12)
                mist.fill(Path(ellipseIn: rect), with: .color(.white.opacity(0.18)))
            }
        case .firefly:
            for i in 0..<3 {
                let point = CGPoint(x: 12 + CGFloat(i * 8), y: 13 + CGFloat((i * 7) % 14))
                var glow = context
                glow.addFilter(.blur(radius: 4))
                glow.fill(Path(ellipseIn: CGRect(x: point.x - 7, y: point.y - 7, width: 14, height: 14)), with: .color(Color.yellow.opacity(0.32)))
                context.fill(Path(ellipseIn: CGRect(x: point.x - 2, y: point.y - 2, width: 4, height: 4)), with: .color(.white.opacity(0.75)))
            }
        }
    }

    private static func petalPath(width: CGFloat, height: CGFloat) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: -width * 0.5, y: 0))
        path.addCurve(
            to: CGPoint(x: width * 0.5, y: 0),
            control1: CGPoint(x: -width * 0.22, y: -height),
            control2: CGPoint(x: width * 0.32, y: -height * 0.85)
        )
        path.addCurve(
            to: CGPoint(x: -width * 0.5, y: 0),
            control1: CGPoint(x: width * 0.28, y: height * 0.95),
            control2: CGPoint(x: -width * 0.26, y: height * 0.75)
        )
        return path
    }
}

// MARK: - Weather Engine Layers

private struct ArtisanRainLayer: View {
    let intensity: Double
    let wind: Double
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let now = timeline.date.timeIntervalSinceReferenceDate
                let bgCount = Int(intensity * 3)
                for i in 0..<bgCount { drawRainLine(into: context, seed: Double(i) * 0.7, now: now, size: size, opacity: 0.15, width: 0.5, speedMult: 0.8) }
                let fgCount = Int(intensity * 4)
                for i in 0..<fgCount { drawRainLine(into: context, seed: Double(i) * 1.3, now: now, size: size, opacity: 0.4, width: 1.2, speedMult: 1.2) }
            }
        }.allowsHitTesting(false)
    }
    private func drawRainLine(into context: GraphicsContext, seed: Double, now: Double, size: CGSize, opacity: Double, width: CGFloat, speedMult: Double) {
        let speed = (900.0 + (sin(seed * 123.4) * 300.0)) * speedMult
        let life: Double = 1.2; let age = (now - seed * 0.08).truncatingRemainder(dividingBy: life)
        let currentY = -150.0 + (speed * age); let currentX = (sin(seed * 456.7) * 0.5 + 0.5) * size.width + (wind * 350 * (age / life)) + (wind * 15 * age)
        if currentY < size.height + 150 {
            var path = Path(); path.move(to: CGPoint(x: currentX, y: currentY)); path.addLine(to: CGPoint(x: currentX + (wind * 3), y: currentY + speed * 0.045))
            context.stroke(path, with: .color(.white.opacity(opacity)), lineWidth: width)
        }
    }
}

private struct ArtisanSnowLayer: View {
    let intensity: Double
    let wind: Double
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let now = timeline.date.timeIntervalSinceReferenceDate
                let count = Int(intensity * 3.5)
                for i in 0..<count {
                    let seed = Double(i); let depth = (sin(seed * 99) * 0.5 + 0.5)
                    let speed = (80.0 + depth * 120.0); let life: Double = 15.0; let age = (now - seed * 0.7).truncatingRemainder(dividingBy: life)
                    let startX = (sin(seed * 321.0) * 0.5 + 0.5) * size.width + (wind * 80 * (age / life)) + sin(age * (1.0 + depth) + seed) * (15.0 + depth * 30.0)
                    let currentY = -40.0 + (speed * age)
                    if currentY < size.height + 40 {
                        let rect = CGRect(x: startX, y: currentY, width: 1.5 + depth * 3.5, height: 1.5 + depth * 3.5)
                        context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(0.2 + depth * 0.5)))
                    }
                }
            }
        }.allowsHitTesting(false)
    }
}

private struct ArtisanLightningLayer: View {
    let frequency: Double
    @Binding var flash: Double
    @State private var bolts: [LightningBolt] = []
    @State private var lastTriggerTime = Date()
    @State private var nextTriggerDelay: TimeInterval = 1.0
    struct LightningBolt: Identifiable { let id = UUID(); let path: Path; let opacity: Double; let width: CGFloat }
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                for bolt in bolts {
                    context.stroke(bolt.path, with: .color(.white.opacity(bolt.opacity)), lineWidth: bolt.width)
                    var glow = context; glow.addFilter(.blur(radius: 4)); glow.stroke(bolt.path, with: .color(.blue.opacity(bolt.opacity * 0.4)), lineWidth: bolt.width * 3)
                }
            }.onChange(of: timeline.date) { date in updateBolts(at: date, size: NSScreen.main?.frame.size ?? CGSize(width: 1920, height: 1080)) }
        }.allowsHitTesting(false)
    }
    private func updateBolts(at now: Date, size: CGSize) {
        if now.timeIntervalSince(lastTriggerTime) > nextTriggerDelay {
            if Double.random(in: 0...1) < frequency / 100.0 {
                let path = generateLightningPath(start: CGPoint(x: Double.random(in: 0...size.width), y: 0), size: size)
                bolts.append(LightningBolt(path: path, opacity: 1.0, width: CGFloat.random(in: 1...3)))
                lastTriggerTime = now; nextTriggerDelay = Double.random(in: 0.2...max(0.5, 10.0 - frequency/10.0))
                withAnimation(.linear(duration: 0.05)) { flash = Double.random(in: 0.5...0.8) }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { withAnimation(.easeOut(duration: 0.5)) { flash = 0 } }
            }
        }
        for i in (0..<bolts.count).reversed() {
            let op = bolts[i].opacity - 0.15
            if op <= 0 { bolts.remove(at: i) } else { bolts[i] = LightningBolt(path: bolts[i].path, opacity: op, width: bolts[i].width) }
        }
    }
    private func generateLightningPath(start: CGPoint, size: CGSize) -> Path {
        var path = Path(); path.move(to: start); var current = start; let segs = 20; let h = size.height / CGFloat(segs)
        for _ in 0..<segs {
            current = CGPoint(x: current.x + CGFloat.random(in: -50...50), y: current.y + h); path.addLine(to: current)
            if Double.random(in: 0...1) < 0.2 {
                var br = current; for _ in 0..<5 { br = CGPoint(x: br.x + CGFloat.random(in: -30...30), y: br.y + CGFloat.random(in: 5...20)); path.move(to: current); path.addLine(to: br) }
                path.move(to: current)
            }
        }
        return path
    }
}

// MARK: - Core Rendering Subviews

private struct ArtisanBackgroundLayer: View {
    let wallpaper: Wallpaper; let contentURL, posterURL: URL?; let blur, grayscale, contrast, saturation, exposure, hue, highlights, shadows, invert, grain, vignette: Double
    var body: some View {
        ZStack {
            if wallpaper.type == .video, let url = contentURL { DetailVideoLayerContainer(url: url).frame(maxWidth: .infinity, maxHeight: .infinity).clipped() }
            else if let url = contentURL { ArtisanSimpleImage(url: url).frame(maxWidth: .infinity, maxHeight: .infinity).clipped() }
            else { ArtisanSimplePoster(url: posterURL) }
            if invert > 50 { Color.white.blendMode(.difference) }
            if grain > 0 { GrainTextureOverlay(opacity: grain / 100.0).blendMode(.overlay) }
            if vignette > 0 { RadialGradient(colors: [.clear, .black.opacity(vignette / 100.0)], center: .center, startRadius: 300, endRadius: 1000) }
        }
        .blur(radius: CGFloat(blur)).grayscale(grayscale / 100.0).contrast(contrast / 100.0).saturation(saturation / 100.0).brightness((exposure - 100) / 100.0).hueRotation(.degrees(hue)).colorMultiply(Color(white: highlights / 100.0))
    }
}

private struct ArtisanSimpleImage: View {
    let url: URL
    var body: some View {
        if url.isFileURL { if let img = NSImage(contentsOf: url) { Image(nsImage: img).resizable().aspectRatio(contentMode: .fill) } else { Color.black } }
        else { AsyncImage(url: url) { ph in if let img = ph.image { img.resizable().aspectRatio(contentMode: .fill) } else { Color.black } } }
    }
}

private struct ArtisanSimplePoster: View {
    let url: URL?
    var body: some View { ZStack { Color.black; if let url = url { ArtisanSimpleImage(url: url).blur(radius: 16).opacity(0.45) } } }
}

private struct DetailVideoLayerContainer: NSViewRepresentable {
    let url: URL
    func makeNSView(context: Context) -> DetailVideoLayerView { let v = DetailVideoLayerView(); v.configure(url: url); return v }
    func updateNSView(_ nsView: DetailVideoLayerView, context: Context) { nsView.configure(url: url) }
    static func dismantleNSView(_ nsView: DetailVideoLayerView, coordinator: ()) { nsView.stop() }
}

private final class DetailVideoLayerView: NSView {
    private let playerLayer = AVPlayerLayer(); private var player: AVPlayer?; private var currentURL: URL?; private var endObserver: NSObjectProtocol?
    init() { super.init(frame: .zero); setup() }
    required init?(coder: NSCoder) { fatalError("init") }
    private func setup() { wantsLayer = true; let r = CALayer(); r.backgroundColor = NSColor.black.cgColor; r.masksToBounds = true; layer = r; playerLayer.videoGravity = .resizeAspectFill; r.addSublayer(playerLayer) }
    func configure(url: URL) {
        guard currentURL != url else { return }; currentURL = url
        if let obs = endObserver { NotificationCenter.default.removeObserver(obs) }; player?.pause()
        let item = AVPlayerItem(url: url); let p = AVPlayer(playerItem: item); p.isMuted = false; p.volume = 1.0; player = p; playerLayer.player = p; p.play()
        endObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main) { [weak self] _ in p.seek(to: .zero); p.play() }
    }
    func stop() { if let obs = endObserver { NotificationCenter.default.removeObserver(obs) }; player?.pause(); playerLayer.player = nil; player = nil; currentURL = nil }
    override func layout() { super.layout(); CATransaction.begin(); CATransaction.setDisableActions(true); playerLayer.frame = bounds; CATransaction.commit() }
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
