import SwiftUI
import AppKit
import AVFoundation

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
    @State private var isDownloading = false
    @State private var toastMessage: String?
    @State private var showToast = false
    @State private var isNavigatingWallpaper = false

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
    @State var particleStyle: String = "circle.fill"
    @State var particleRate: Double = 60
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
        .overlay { toastOverlay }
        .preferredColorScheme(.dark)
        .onAppear {
            if wallpaper.type == .video, let videoURL = wallpaperContentURL {
                VideoPreloader.shared.preload(url: videoURL)
            }
        }
    }
    
    // MARK: - Subviews

    private var chromeOverlay: some View {
        ZStack {
            HStack {
                if onPrevious != nil {
                    navigationEdgeButton(direction: -1, isHovered: $isLeftEdgeHovered)
                        .padding(.leading, 24)
                        .transition(.opacity)
                }

                Spacer(minLength: 0)

                if onNext != nil {
                    navigationEdgeButton(direction: 1, isHovered: $isRightEdgeHovered)
                        .padding(.trailing, 24)
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

                if isStudioActive {
                    artisanStudioHUD
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .opacity
                        ))
                        .padding(.bottom, 24)
                }

                artisanMainDock
                    .padding(.bottom, 40)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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

            if isStudioActive && studioTab == 4 && particleRate > 0 {
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
                // 核心：极高对比度背景 (黑色渐变盾牌)
                Circle()
                    .fill(Color.black.opacity(isHovered.wrappedValue ? 0.8 : 0.2))
                    .frame(width: 64, height: 64)
                    .blur(radius: isHovered.wrappedValue ? 2 : 12)
                    .background(Circle().fill(.ultraThinMaterial))
                    .overlay(Circle().stroke(Color.white.opacity(isHovered.wrappedValue ? 0.5 : 0.2), lineWidth: 1.5))
                
                navigationChevron(isPrevious: direction < 0)
                    .frame(width: 20, height: 48)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.8), radius: 4)
            }
            .scaleEffect(isHovered.wrappedValue ? 1.05 : 1.0)
            .frame(width: 140, height: 320) // 增加宽度提高热区，限制高度防止遮挡
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isNavigatingWallpaper)
        .onHover { h in withAnimation(.galleryEase) { isHovered.wrappedValue = h } }
        .padding(direction < 0 ? .leading : .trailing, 10)
        .keyboardShortcut(direction < 0 ? .leftArrow : .rightArrow, modifiers: [])
    }

    private func navigationChevron(isPrevious: Bool) -> some View {
        RoundedChevron()
            .stroke(.white, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
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
            ZStack {
                Circle()
                    .fill(Color.black.opacity(isCloseHovered ? 0.8 : 0.6))
                    .frame(width: 48, height: 48)
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
            }
            .background(.ultraThinMaterial, in: Circle())
            .overlay(Circle().stroke(Color.white.opacity(isCloseHovered ? 0.6 : 0.3), lineWidth: 2))
            .scaleEffect(isCloseHovered ? 1.1 : 1.0)
            .artisanShadow(color: .black, radius: 10)
        }
        .buttonStyle(.plain)
        .onHover { h in withAnimation(.galleryEase) { isCloseHovered = h } }
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
                    Text("实验室").font(.system(size: 8, weight: .bold))
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
            VStack(spacing: 6) {
                ArtisanHorizonTab(icon: "grid", label: "预设", isSelected: studioTab == 0) { withAnimation { studioTab = 0 } }
                ArtisanHorizonTab(icon: "camera.filters", label: "光学", isSelected: studioTab == 1) { withAnimation { studioTab = 1 } }
                ArtisanHorizonTab(icon: "crop", label: "风格", isSelected: studioTab == 2) { withAnimation { studioTab = 2 } }
                ArtisanHorizonTab(icon: "cloud.sun", label: "天气", isSelected: studioTab == 3) { withAnimation { studioTab = 3 } }
                ArtisanHorizonTab(icon: "sparkles", label: "粒子", isSelected: studioTab == 4) { withAnimation { studioTab = 4 } }
            }
            .frame(width: 84, height: 220).background(Color.white.opacity(0.01))
            Divider().frame(width: 1, height: 220).opacity(0.06)
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 24) {
                    if studioTab == 4 { particleStyleRow }
                    else {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("MODE: CURATED").font(.system(size: 6.5, weight: .black)).opacity(0.15).kerning(1.5)
                            Text(currentTabLabel.uppercased()).font(.system(size: 10, weight: .medium)).kerning(2.5)
                        }
                        Spacer()
                    }
                    if studioTab == 4 {
                        HStack(spacing: 16) {
                            colorPreview(label: "START", color: $particleColorStart)
                            colorPreview(label: "END", color: $particleColorEnd)
                        }
                    }
                }
                .padding(.horizontal, 40).padding(.top, 24).padding(.bottom, 12).frame(height: 64).border(width: 0.5, edges: [.bottom], color: .white.opacity(0.04))
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        parameterGrid
                        if studioTab == 4 {
                            Text("SCROLL FOR MORE").font(.system(size: 6.5, weight: .bold)).opacity(0.08).kerning(1.5).padding(.vertical, 20)
                        }
                    }
                }.frame(height: 156) 
            }.frame(width: 740, height: 220)
            Divider().frame(width: 1, height: 220).opacity(0.06)
            VStack(spacing: 24) {
                Button(action: { resetFilters() }) {
                    VStack(spacing: 4) { Text("↺").font(.system(size: 14)); Text("RESET").font(.system(size: 6.5, weight: .black)) }
                    .foregroundStyle(.white.opacity(0.2)).frame(width: 44, height: 44).background(Circle().fill(.white.opacity(0.02)))
                }.buttonStyle(.plain)
                Button(action: { applyCurrentPreset() }) {
                    VStack(spacing: 4) { Image(systemName: "checkmark").font(.system(size: 11)); Text("APPLY").font(.system(size: 6.5, weight: .black)) }
                    .foregroundStyle(.black).frame(width: 44, height: 44).background(Circle().fill(LiquidGlassColors.primaryPink))
                }.buttonStyle(.plain)
            }.padding(.vertical, 20).frame(width: 80)
        }
        .frame(height: 220).background(LiquidGlassColors.deepBackground.opacity(0.7)).background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous)).artisanShadow(color: .black.opacity(0.4), radius: 60)
    }

    private var currentTabLabel: String {
        ["Presets", "Optics", "Style", "Weather", "Particles"][studioTab]
    }

    private func colorPreview(label: String, color: Binding<Color>) -> some View {
        VStack(spacing: 4) {
            Text(label).font(.system(size: 6, weight: .black)).opacity(0.2)
            ColorPicker("", selection: color).labelsHidden().frame(width: 20, height: 20).clipShape(Circle())
        }
    }

    private var particleStyleRow: some View {
        HStack(spacing: 24) {
            Text("STYLES").font(.system(size: 7, weight: .black)).opacity(0.15).kerning(1.2)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 24) {
                    ForEach(["circle.fill", "sparkle", "sparkles", "star.fill", "aqi.medium", "sun.max.fill", "leaf.fill", "flower.fill", "drop.fill", "snowflake", "cloud.fill"], id: \.self) { icon in
                        Button(action: { withAnimation { particleStyle = icon } }) {
                            Image(systemName: icon).font(.system(size: 13, weight: .light))
                                .foregroundStyle(particleStyle == icon ? LiquidGlassColors.primaryPink : .white.opacity(0.12))
                        }.buttonStyle(.plain)
                    }
                }
            }
            Spacer()
        }
    }

    @ViewBuilder
    private var parameterGrid: some View {
        if studioTab == 0 {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                ForEach(BuiltInPreset.allCases) { preset in
                    let isActive = currentPresetName == preset.name
                    Button(action: { applyPreset(preset) }) {
                        Text(preset.name).font(.system(size: 9.5, weight: .bold)).frame(maxWidth: .infinity).frame(height: 40)
                            .background(isActive ? LiquidGlassColors.primaryPink.opacity(0.12) : Color.white.opacity(0.02))
                            .foregroundStyle(isActive ? LiquidGlassColors.primaryPink : .white.opacity(0.3)).clipShape(Capsule())
                    }.buttonStyle(.plain)
                }
            }.padding(32)
        } else if studioTab == 1 {
            VStack(spacing: 24) {
                HStack(spacing: 40) {
                    ArtisanRulerDial(label: "曝光", value: $exposure, range: 0...200, unit: "ev")
                    ArtisanRulerDial(label: "对比度", value: $contrast, range: 50...150, unit: "%")
                    ArtisanRulerDial(label: "饱和度", value: $saturation, range: 0...200, unit: "%")
                }
                HStack(spacing: 40) {
                    ArtisanRulerDial(label: "色相", value: $hue, range: -180...180, unit: "°")
                    ArtisanRulerDial(label: "高光", value: $highlights, range: 0...200, unit: "%")
                    ArtisanRulerDial(label: "阴影", value: $shadows, range: 0...200, unit: "%")
                }
            }.padding(32)
        } else if studioTab == 2 {
            VStack(spacing: 24) {
                HStack(spacing: 40) {
                    ArtisanRulerDial(label: "模糊", value: $blur, range: 0...40, unit: "px")
                    ArtisanRulerDial(label: "噪点", value: $grain, range: 0...100, unit: "%")
                    ArtisanRulerDial(label: "暗角", value: $vignette, range: 0...100, unit: "%")
                }
                HStack(spacing: 40) {
                    ArtisanRulerDial(label: "黑白", value: $grayscale, range: 0...100, unit: "%")
                    ArtisanRulerDial(label: "反相", value: $invert, range: 0...100, unit: "%")
                    ArtisanRulerDial(label: "色散", value: $dispersion, range: 0...20, unit: "px")
                }
            }.padding(32)
        } else if studioTab == 3 {
            VStack(spacing: 32) {
                HStack(spacing: 40) {
                    ArtisanRulerDial(label: "全局风力", value: $weatherWind, range: -50...50, unit: "km/h")
                    ArtisanRulerDial(label: "降雨强度", value: $weatherRain, range: 0...100, unit: "%")
                    ArtisanRulerDial(label: "降雪密度", value: $weatherSnow, range: 0...100, unit: "%")
                }
                HStack(spacing: 40) {
                    ArtisanRulerDial(label: "雷电频率", value: $weatherThunder, range: 0...100, unit: "%")
                    Spacer().frame(width: 150); Spacer().frame(width: 150)
                }
            }.padding(32)
        } else if studioTab == 4 {
            VStack(spacing: 32) {
                HStack(spacing: 40) {
                    ArtisanRulerDial(label: "速率", value: $particleRate, range: 1...300, unit: "p/s")
                    ArtisanRulerDial(label: "寿命", value: $particleLifetime, range: 0.1...10, unit: "s")
                    ArtisanRulerDial(label: "尺寸", value: $particleSize, range: 1...40, unit: "px")
                }
                HStack(spacing: 40) {
                    ArtisanRulerDial(label: "自旋", value: $particleSpin, range: 0...20, unit: "deg")
                    ArtisanRulerDial(label: "扰动", value: $particleTurbulence, range: 0...20, unit: "px")
                    ArtisanRulerDial(label: "重力", value: $particleGravity, range: -20...20, unit: "m/s²")
                }
                HStack(spacing: 40) {
                    ArtisanRulerDial(label: "推力", value: $particleThrust, range: 0...50, unit: "pow")
                    ArtisanRulerDial(label: "渐显", value: $particleFadeIn, range: 0...100, unit: "%")
                    ArtisanRulerDial(label: "渐隐", value: $particleFadeOut, range: 0...100, unit: "%")
                }
            }.padding(32)
        }
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
            if wallpaper.type == .video {
                let path = highQualityVideoPathForApply ?? wallpaper.filePath
                let videoURL = URL(string: path)?.scheme != nil ? try await downloadTemp(URL(string: path)!) : URL(fileURLWithPath: path)
                try await RenderPipeline.shared.setWallpaper(url: videoURL)
            } else {
                let imageURL = URL(string: wallpaper.filePath)?.scheme != nil ? try await downloadTemp(URL(string: wallpaper.filePath)!) : URL(fileURLWithPath: wallpaper.filePath)
                try await MainActor.run { try WallpaperSetter.shared.setWallpaper(imageURL: imageURL) }
            }
            showToastMessage("设置成功")
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
        isDownloading = true; defer { isDownloading = false }
        do {
            let downloadsDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!.appendingPathComponent("PlumWallPaper/Downloads", isDirectory: true)
            try FileManager.default.createDirectory(at: downloadsDir, withIntermediateDirectories: true)
            let localURL = downloadsDir.appendingPathComponent("\(wallpaper.name)_\(wallpaper.id.uuidString.prefix(8)).\(wallpaper.type == .video ? "mp4" : "jpg")")
            let (data, _) = try await URLSession.shared.data(from: remoteURL)
            try data.write(to: localURL)
            let newWp = Wallpaper(name: wallpaper.name, filePath: localURL.path, type: wallpaper.type, resolution: wallpaper.resolution, fileSize: Int64(data.count), thumbnailPath: wallpaper.thumbnailPath, source: .downloaded, remoteId: wallpaper.remoteId, remoteSource: wallpaper.remoteSource, remoteMetadata: wallpaper.remoteMetadata)
            modelContext.insert(newWp); try modelContext.save()
            wallpaper.filePath = localURL.path; wallpaper.source = .downloaded
            onDownload?(wallpaper); showToastMessage("下载完成")
        } catch { showToastMessage("失败: \(error.localizedDescription)") }
    }

    private func applyCurrentPreset() {
        if wallpaper.shaderPreset == nil { wallpaper.shaderPreset = ShaderPreset(name: currentPresetName) }
        else { wallpaper.shaderPreset?.name = currentPresetName }
        try? modelContext.save(); showToastMessage("已保存预设")
    }

    private func showToastMessage(_ message: String) {
        toastMessage = message; showToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { withAnimation { showToast = false } }
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
