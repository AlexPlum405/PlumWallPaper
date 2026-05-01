import SwiftUI

// MARK: - Artisan Exhibition Hall (Scheme C: Artisan Gallery)
// 沉浸式壁纸鉴赏厅，UI 仅在鼠标触碰功能区时如雾般浮现。

struct WallpaperDetailView: View {
    @State var wallpaper: Wallpaper // 改为 @State 以支持内部平滑更新
    var onPrevious: ((@escaping (Wallpaper) -> Void) -> Void)? = nil
    var onNext: ((@escaping (Wallpaper) -> Void) -> Void)? = nil
    
    @Environment(\.dismiss) private var dismiss
    
    // 状态驱动
    @State internal var isStudioActive = false      // 实验室面板是否展开
    @State internal var studioTab = 0               // 0: 预设, 1: 光学, 2: 风格, 3: 粒子
    @State internal var isApplying = false           // 应用壁纸中

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

    @State var isShowingShaderEditor = false
    
    var body: some View {
        ZStack {
            // 1. 底层：纯净画布（100% 视野）
            fullscreenCanvas

            // 2. 交互辅助层：透明拖拽与背景点击
            Color.clear.contentShape(Rectangle()).windowDragGesture()

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

            // 6. 关闭按钮（右上角）
            closeButtonHUD
        }
        .sheet(isPresented: $isShowingShaderEditor) {
            ShaderEditorView()
        }
        .frame(minWidth: 1200, minHeight: 800)
        .preferredColorScheme(.dark)
    }
    
    // MARK: - A. 视觉子层级 (Artisan Horizon HUD)
    
    private var fullscreenCanvas: some View {
        ZStack {
            if let url = URL(string: wallpaper.filePath) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable().aspectRatio(contentMode: .fit) // .fit 确保不裁切
                    } else { Color.black }
                }
            } else { Color.black }
            // 径向暗角
            RadialGradient(colors: [.clear, .black.opacity(0.3)], center: .center, startRadius: 300, endRadius: 1000)
        }
        .background(Color.black)
        .ignoresSafeArea()
    }

    private var sideNavigationArrows: some View {
        ZStack {
            // 左侧感应区：晶莹圆润箭头
            Color.clear
                .frame(width: 80)
                .contentShape(Rectangle())
                .onHover { hovering in withAnimation(.galleryEase) { isLeftEdgeHovered = hovering } }
                .onTapGesture { 
                    onPrevious? { newWallpaper in
                        withAnimation(.galleryEase) {
                            self.wallpaper = newWallpaper
                        }
                    }
                }
                .overlay(
                    ZStack {
                        // 1. 底层：弥散柔光
                        RoundedChevron()
                            .stroke(LiquidGlassColors.primaryPink.opacity(0.3), style: StrokeStyle(lineWidth: 12, lineCap: .round, lineJoin: .round))
                            .blur(radius: 8)
                        
                        // 2. 中层：实体厚度 (白瓷质感)
                        RoundedChevron()
                            .stroke(.white.opacity(0.6), style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                        
                        // 3. 顶层：棱镜高光
                        RoundedChevron()
                            .stroke(
                                LinearGradient(colors: [.white, .white.opacity(0.2)], startPoint: .top, endPoint: .bottom),
                                style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                            )
                    }
                    .frame(width: 14, height: 44)
                    .rotationEffect(.degrees(180))
                    .opacity(isLeftEdgeHovered ? 1 : 0)
                    .offset(x: isLeftEdgeHovered ? 40 : 10),
                    alignment: .leading
                )
                .frame(maxWidth: .infinity, alignment: .leading)

            // 右侧感应区：晶莹圆润箭头
            Color.clear
                .frame(width: 80)
                .contentShape(Rectangle())
                .onHover { hovering in withAnimation(.galleryEase) { isRightEdgeHovered = hovering } }
                .onTapGesture { 
                    onNext? { newWallpaper in
                        withAnimation(.galleryEase) {
                            self.wallpaper = newWallpaper
                        }
                    }
                }
                .overlay(
                    ZStack {
                        // 1. 底层：弥散柔光
                        RoundedChevron()
                            .stroke(LiquidGlassColors.primaryPink.opacity(0.3), style: StrokeStyle(lineWidth: 12, lineCap: .round, lineJoin: .round))
                            .blur(radius: 8)
                        
                        // 2. 中层：实体厚度
                        RoundedChevron()
                            .stroke(.white.opacity(0.6), style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                        
                        // 3. 顶层：棱镜高光
                        RoundedChevron()
                            .stroke(
                                LinearGradient(colors: [.white, .white.opacity(0.2)], startPoint: .top, endPoint: .bottom),
                                style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
                            )
                    }
                    .frame(width: 14, height: 44)
                    .opacity(isRightEdgeHovered ? 1 : 0)
                    .offset(x: isRightEdgeHovered ? -40 : -10),
                    alignment: .trailing
                )
                .frame(maxWidth: .infinity, alignment: .trailing)
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
            ) { /* 收藏逻辑 */ }

            // 2. 应用壁纸（主按钮，粉色胶囊）
            Button(action: {
                isApplying = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { isApplying = false }
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
            }.buttonStyle(.plain)

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
            actionCircleButton(icon: "arrow.down.to.line.compact", color: .white.opacity(0.6)) { }
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

                Button(action: { /* 应用 */ }) {
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
                    ColorPicker("", selection: .constant(Color.white)).labelsHidden()
                    Image(systemName: "arrow.right").font(.system(size: 8)).opacity(0.2)
                    ColorPicker("", selection: .constant(LiquidGlassColors.primaryPink)).labelsHidden()
                }
            }

            Divider().frame(height: 60).opacity(0.1)

            // 粒子参数旋钮
            ArtisanRulerDial(label: "速率", value: .constant(60), range: 1...300, unit: "p/s")
            ArtisanRulerDial(label: "寿命", value: .constant(3), range: 0.1...10, unit: "s")
            ArtisanRulerDial(label: "尺寸", value: .constant(4), range: 1...40, unit: "px")
            ArtisanRulerDial(label: "重力", value: .constant(9.8), range: -20...20, unit: "m/s²")
            ArtisanRulerDial(label: "扰动", value: .constant(2), range: 0...20, unit: "px")
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

// MARK: - Required Components (Duplicated from ArtisanControls.swift to bypass build issues)

struct ArtisanRulerDial: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let unit: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(label)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(LiquidGlassColors.textSecondary)
                Spacer()
                Text("\(Int(value))")
                    .font(.system(size: 20, weight: .light, design: .serif))
                    .foregroundStyle(.white)
                Text(unit)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(LiquidGlassColors.primaryPink)
            }
            .padding(.horizontal, 2)
            
            ZStack {
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 1)
                
                HStack(spacing: 6) {
                    ForEach(0..<21) { i in
                        Rectangle()
                            .fill(i % 5 == 0 ? Color.white.opacity(0.5) : Color.white.opacity(0.2))
                            .frame(width: 1, height: i % 5 == 0 ? 10 : 5)
                    }
                }
                
                Rectangle()
                    .fill(LiquidGlassColors.primaryPink)
                    .frame(width: 2, height: 16)
                    .artisanShadow(color: LiquidGlassColors.primaryPink.opacity(0.5), radius: 4)
                
                Slider(value: $value, in: range)
                    .accentColor(.clear)
                    .opacity(0.01)
            }
            .frame(height: 20)
        }
        .frame(width: 130)
    }
}

struct ArtisanHorizonTab: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(isSelected ? .black : .white)
                    .frame(width: 40, height: 40)
                    .background(isSelected ? LiquidGlassColors.primaryPink : Color.white.opacity(0.05))
                    .clipShape(Circle())
                
                Text(label)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(isSelected ? LiquidGlassColors.primaryPink : .white.opacity(0.4))
            }
        }
        .buttonStyle(.plain)
    }
}
