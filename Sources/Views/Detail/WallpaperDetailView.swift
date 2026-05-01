import SwiftUI

struct WallpaperDetailView: View {
    let wallpaper: Wallpaper
    var onPrevious: (() -> Void)? = nil
    var onNext: (() -> Void)? = nil
    
    @Environment(\.dismiss) private var dismiss
    
    // === 交互状态控制 (增加了防抖感应) ===
    @State private var isLeftHovered = false
    @State private var isRightHovered = false
    @State private var isTopHovered = false
    @State private var isBottomHovered = false
    @State private var isCloseButtonHovered = false
    
    @State private var isEditingShaders = false
    @State private var isApplying = false
    
    // 任务 2: 显示器选择状态
    @State private var selectedDisplays: Set<String> = ["built-in"]
    private let mockDisplays = [
        (id: "built-in", name: "内建显示器", icon: "laptopcomputer"),
        (id: "external-1", name: "Studio Display", icon: "display"),
        (id: "external-2", name: "LG UltraFine", icon: "display")
    ]
    
    // 滤镜参数状态
    @State private var exposure: Double = 100
    @State private var contrast: Double = 100
    @State private var saturation: Double = 100
    @State private var hue: Double = 0
    @State private var blur: Double = 0
    @State private var grain: Double = 0
    @State private var vignette: Double = 0
    @State private var grayscale: Double = 0
    @State private var invert: Double = 0
    @State private var currentPresetName: String = "原始"
    
    private let sidebarWidth: CGFloat = 380
    private let fadeAnim = Animation.easeInOut(duration: 0.3)
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 1. 全屏背景 (底层)
                ZStack {
                    if let url = URL(string: wallpaper.filePath), url.scheme != nil {
                        AsyncImage(url: url) { image in
                            image.resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: { Color.black }
                    } else { Color.black }
                }
                .ignoresSafeArea()

                // 2. 左侧：艺术化标题 HUD (左侧 25% 宽度)
                HStack(spacing: 0) {
                    VStack {
                        artisticTitleView
                            .padding(.leading, 80)
                            .opacity(isLeftHovered ? 1 : 0)
                    }
                    .frame(width: geometry.size.width * 0.25)
                    .frame(maxHeight: .infinity)
                    .contentShape(Rectangle())
                    .onHover { hovering in
                        withAnimation(fadeAnim) { isLeftHovered = hovering }
                    }

                    Spacer()
                }

                // 3. 右侧：感应侧边栏 (固定宽度，全高度，最高优先级)
                HStack {
                    Spacer()
                    rightSidebarContent
                        .opacity(isRightHovered ? 1 : 0)
                        .frame(width: sidebarWidth)
                        .frame(maxHeight: .infinity)
                        .contentShape(Rectangle())
                        .onHover { hovering in
                            withAnimation(fadeAnim) { isRightHovered = hovering }
                        }
                }

                // 4. 顶部：上一张导航 (中间区域，避开左右)
                VStack {
                    HStack {
                        Spacer()
                            .frame(width: geometry.size.width * 0.25)

                        navArrowHUD(icon: "chevron.up") { onPrevious?() }
                            .opacity(isTopHovered ? 0.7 : 0)
                            .padding(.top, 30)
                            .frame(maxWidth: .infinity)
                            .frame(height: 100)
                            .contentShape(Rectangle())
                            .onHover { hovering in
                                withAnimation(fadeAnim) { isTopHovered = hovering }
                            }

                        Spacer()
                            .frame(width: sidebarWidth)
                    }
                    Spacer()
                }

                // 5. 底部：核心动作胶囊 + 下一张 (中间区域，避开左右)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                            .frame(width: geometry.size.width * 0.25)

                        VStack(spacing: 28) {
                            HStack(spacing: 24) {
                                actionCircleButton(icon: wallpaper.isFavorite ? "heart.fill" : "heart", color: wallpaper.isFavorite ? LiquidGlassColors.primaryPink : .white.opacity(0.8)) { }

                                Button(action: {
                                    isApplying = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { isApplying = false }
                                }) {
                                    HStack(spacing: 12) {
                                        if isApplying { ProgressView().tint(.white).controlSize(.small) }
                                        else {
                                            Image(systemName: "play.fill")
                                            Text("APPLY WALLPAPER").font(.system(size: 14, weight: .bold)).kerning(1.2)
                                        }
                                    }
                                    .padding(.horizontal, 36)
                                    .frame(height: 52)
                                    .background(
                                        Capsule().fill(LinearGradient(colors: [LiquidGlassColors.primaryPink.opacity(0.8), LiquidGlassColors.secondaryViolet.opacity(0.8)], startPoint: .leading, endPoint: .trailing))
                                    )
                                    .overlay(Capsule().stroke(.white.opacity(0.2), lineWidth: 0.5))
                                    .shadow(color: LiquidGlassColors.primaryPink.opacity(0.2), radius: 15, y: 8)
                                }
                                .buttonStyle(.plain)

                                actionCircleButton(icon: "square.and.arrow.down", color: .white.opacity(0.8)) { }
                            }
                            .padding(10)
                            .background(Capsule().fill(.white.opacity(0.05)).background(VisualEffectView(material: .hudWindow, blendingMode: .behindWindow).clipShape(Capsule())))
                            .overlay(Capsule().stroke(.white.opacity(0.1), lineWidth: 0.5))
                            .opacity(isBottomHovered ? 1 : 0)

                            navArrowHUD(icon: "chevron.down") { onNext?() }
                                .opacity(isBottomHovered ? 0.7 : 0)
                        }
                        .padding(.bottom, 30)
                        .frame(maxWidth: .infinity)
                        .frame(height: 180)
                        .contentShape(Rectangle())
                        .onHover { hovering in
                            withAnimation(fadeAnim) { isBottomHovered = hovering }
                        }

                        Spacer()
                            .frame(width: sidebarWidth)
                    }
                }

                // 6. 左上角：返回感应
                closeButtonHUD
            }
        }
        .frame(minWidth: 1100, minHeight: 750)
        .preferredColorScheme(.dark)
    }
    
    // MARK: - A. 左侧艺术标题
    private var artisticTitleView: some View {
        VStack(alignment: .leading, spacing: 14) {
            // 分类标签
            Text("Featured Curation")
                .font(.system(size: 11, weight: .bold))
                .kerning(3)
                .foregroundStyle(LiquidGlassColors.primaryPink)
                .padding(.leading, 2)
            
            VStack(alignment: .leading, spacing: -5) {
                Text(wallpaper.name.prefix(1))
                    .font(.custom("Georgia", size: 120))
                    .fontWeight(.light)
                    .foregroundStyle(.white.opacity(0.15))
                    .offset(x: -15, y: 30)
                
                Text(wallpaper.name)
                    .font(.custom("Georgia", size: 64))
                    .fontWeight(.light)
                    .foregroundStyle(.white)
            }
            
            Rectangle()
                .fill(LinearGradient(colors: [LiquidGlassColors.primaryPink.opacity(0.6), .clear], startPoint: .leading, endPoint: .trailing))
                .frame(width: 150, height: 1)
            
            Text("PRECISION RENDERING · 8K IMMERSIVE")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.4))
                .padding(.leading, 2)
        }
    }
    
    // MARK: - B. 右侧侧边栏内容
    private var rightSidebarContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            if isEditingShaders {
                shaderEditorPanel
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .trailing)))
            } else {
                VStack(alignment: .leading, spacing: 32) {
                    Text("详细信息").font(.system(size: 11, weight: .bold)).kerning(2.5).foregroundStyle(.white.opacity(0.3))

                    VStack(spacing: 20) {
                        metadataRow(icon: "dot.circle.and.hand.point.up.left.fill", label: "分辨率", value: wallpaper.resolution ?? "未知")
                        metadataRow(icon: "doc.fill", label: "文件大小", value: ByteCountFormatter.string(fromByteCount: wallpaper.fileSize, countStyle: .file))
                        if let fps = wallpaper.frameRate, fps > 0 {
                            metadataRow(icon: "speedometer", label: "帧率", value: "\(Int(fps)) FPS")
                        }
                        if let dur = wallpaper.duration, dur > 0 {
                            metadataRow(icon: "timer", label: "时长", value: String(format: "%.1f 秒", dur))
                        }
                        metadataRow(icon: "calendar", label: "导入时间", value: wallpaper.importDate.formatted(date: .abbreviated, time: .omitted))
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("标签").font(.system(size: 10, weight: .bold)).foregroundStyle(.white.opacity(0.3))
                        FlowLayout(spacing: 8) {
                            ForEach(wallpaper.tags) { tag in
                                Text(tag.name).font(.system(size: 10, weight: .medium)).padding(.horizontal, 10).padding(.vertical, 5)
                                    .background(Capsule().fill(.white.opacity(0.08))).foregroundStyle(.white.opacity(0.6))
                            }
                        }
                    }

                    // 任务 2: 显示器选择 UI
                    displaySelectionSection

                    Spacer()

                    featureEntry(title: "着色器特效", icon: "sparkles", description: "调节高级后期渲染参数") {
                        withAnimation(fadeAnim) { isEditingShaders = true }
                    }
                }
                .padding(40)
            }
        }
        .frame(width: sidebarWidth)
        .background(VisualEffectView(material: .hudWindow, blendingMode: .withinWindow).overlay(Color.black.opacity(0.2)))
    }

    private var displaySelectionSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("应用到显示器").font(.system(size: 10, weight: .bold)).foregroundStyle(.white.opacity(0.3)).kerning(1)

            VStack(spacing: 10) {
                ForEach(mockDisplays, id: \.id) { display in
                    displayCard(display: display)
                }
            }
        }
    }

    private func displayCard(display: (id: String, name: String, icon: String)) -> some View {
        let isSelected = selectedDisplays.contains(display.id)

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                if selectedDisplays.contains(display.id) {
                    if selectedDisplays.count > 1 {
                        selectedDisplays.remove(display.id)
                    }
                } else {
                    selectedDisplays.insert(display.id)
                }
            }
        } label: {
            HStack(spacing: 12) {
                // 显示器图标/预览缩略图占位
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(isSelected ? LiquidGlassColors.primaryPink.opacity(0.15) : Color.white.opacity(0.05))

                    Image(systemName: display.icon)
                        .font(.system(size: 14))
                        .foregroundStyle(isSelected ? LiquidGlassColors.primaryPink : .white.opacity(0.4))
                }
                .frame(width: 36, height: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(display.name)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(isSelected ? .white : .white.opacity(0.7))

                    if isSelected {
                        Text("当前选择")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(LiquidGlassColors.primaryPink.opacity(0.8))
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(LiquidGlassColors.primaryPink)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? Color.white.opacity(0.05) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? LiquidGlassColors.primaryPink.opacity(0.3) : Color.white.opacity(0.05), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    // MARK: - E. 导航箭头组件
    private func navArrowHUD(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 50, height: 32)
                .background(Capsule().fill(.white.opacity(0.1)).background(VisualEffectView(material: .hudWindow, blendingMode: .behindWindow).clipShape(Capsule())))
                .overlay(Capsule().stroke(.white.opacity(0.1), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }
    
    private func actionCircleButton(icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(color)
                .frame(width: 52, height: 52)
                .background(Circle().fill(.white.opacity(0.1)))
                .overlay(Circle().stroke(.white.opacity(0.1), lineWidth: 0.5))
        }.buttonStyle(.plain)
    }
    
    // MARK: - 左上角关闭按钮
    private var closeButtonHUD: some View {
        VStack {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(.black.opacity(0.3)))
                        .overlay(Circle().stroke(.white.opacity(0.2), lineWidth: 0.5))
                }
                .buttonStyle(.plain)
                .padding(32)
                .opacity(isCloseButtonHovered || isTopHovered || isLeftHovered ? 1 : 0)
                .onHover { isCloseButtonHovered = $0 }
                
                Spacer()
            }
            Spacer()
        }
    }

    // 辅助方法 (metadataRow, featureEntry) 保持一致
    private func metadataRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 13)).foregroundStyle(.white.opacity(0.3)).frame(width: 18)
            Text(label).font(.system(size: 12)).foregroundStyle(.white.opacity(0.4))
            Spacer(); Text(value).font(.system(size: 12, weight: .medium)).foregroundStyle(.white.opacity(0.9))
        }
    }
    
    private func featureEntry(title: String, icon: String, description: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Image(systemName: icon).font(.system(size: 16)).foregroundStyle(LiquidGlassColors.primaryPink).frame(width: 36, height: 36).background(LiquidGlassColors.primaryPink.opacity(0.1)).clipShape(RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 2) { Text(title).font(.system(size: 13, weight: .semibold)); Text(description).font(.system(size: 10)).foregroundStyle(.white.opacity(0.4)) }
                Spacer(); Image(systemName: "chevron.right").font(.system(size: 10, weight: .bold)).foregroundStyle(.white.opacity(0.2))
            }.padding(15).background(Color.white.opacity(0.04)).clipShape(RoundedRectangle(cornerRadius: 12)).overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.08), lineWidth: 1))
        }.buttonStyle(.plain)
    }
    
    private var shaderEditorPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("色彩调节").font(.system(size: 14, weight: .bold)).kerning(2).foregroundStyle(.white.opacity(0.5))
                Spacer()
                Button("重置") { resetFilters() }
                    .font(.system(size: 11)).foregroundStyle(LiquidGlassColors.primaryPink).buttonStyle(.plain)
                Button(action: { withAnimation { isEditingShaders = false } }) {
                    Image(systemName: "xmark").font(.system(size: 12)).foregroundStyle(.white.opacity(0.5))
                }.buttonStyle(.plain).padding(.leading, 12)
            }.padding(.horizontal, 28).padding(.vertical, 20)

            ScrollView {
                VStack(spacing: 28) {
                    // 预设
                    presetSection

                    // 基础
                    filterSection(header: "基础") {
                        filterSlider(label: "曝光", value: $exposure, range: 0...200, unit: "%")
                        filterSlider(label: "对比度", value: $contrast, range: 50...150, unit: "%")
                        filterSlider(label: "饱和度", value: $saturation, range: 0...200, unit: "%")
                        filterSlider(label: "色相", value: $hue, range: -180...180, unit: "°")
                    }

                    // 艺术
                    filterSection(header: "艺术") {
                        filterSlider(label: "模糊", value: $blur, range: 0...20, unit: "px")
                        filterSlider(label: "颗粒", value: $grain, range: 0...100, unit: "%")
                        filterSlider(label: "暗角", value: $vignette, range: 0...100, unit: "%")
                    }

                    // 滤镜
                    filterSection(header: "滤镜") {
                        filterSlider(label: "灰度", value: $grayscale, range: 0...100, unit: "%")
                        filterSlider(label: "反相", value: $invert, range: 0...100, unit: "%")
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
        }
    }

    // MARK: - 预设芯片
    private var presetSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("预设").font(.system(size: 10, weight: .bold)).foregroundStyle(.white.opacity(0.3)).kerning(1)
            builtInPresetChips
        }
    }

    private var builtInPresetChips: some View {
        FlowLayout(spacing: 8) {
            ForEach(BuiltInPreset.allCases) { preset in
                Button {
                    applyPreset(preset)
                } label: {
                    Text(preset.name)
                        .font(.system(size: 11, weight: .medium))
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Capsule().fill(currentPresetName == preset.name ? LiquidGlassColors.primaryPink.opacity(0.15) : .white.opacity(0.05)))
                        .overlay(Capsule().stroke(currentPresetName == preset.name ? LiquidGlassColors.primaryPink.opacity(0.6) : .white.opacity(0.12), lineWidth: 1))
                        .foregroundStyle(currentPresetName == preset.name ? LiquidGlassColors.primaryPink : .white.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
        }
    }
    // MARK: - 滤镜滑块组件
    private func filterSlider(label: String, value: Binding<Double>, range: ClosedRange<Double>, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label).font(.system(size: 12)).foregroundStyle(.white.opacity(0.7))
                Spacer()
                Text("\(Int(value.wrappedValue))\(unit)")
                    .font(.system(size: 11, design: .monospaced)).foregroundStyle(.white.opacity(0.4))
            }
            Slider(value: value, in: range)
                .tint(LiquidGlassColors.primaryPink)
        }
    }

    private func filterSection<Content: View>(header: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(header).font(.system(size: 10, weight: .bold)).foregroundStyle(.white.opacity(0.3)).kerning(1)
            VStack(spacing: 20) { content() }
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 10).fill(.white.opacity(0.04)))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(.white.opacity(0.08), lineWidth: 0.5))
        }
    }

    // MARK: - 预设操作
    private func applyPreset(_ preset: BuiltInPreset) {
        withAnimation(.easeInOut(duration: 0.2)) {
            currentPresetName = preset.name
            exposure = preset.exposure; contrast = preset.contrast
            saturation = preset.saturation; hue = preset.hue
            blur = preset.blur; grain = preset.grain
            vignette = preset.vignette; grayscale = preset.grayscale
            invert = preset.invert
        }
    }

    private func resetFilters() {
        applyPreset(.original)
    }
}

// MARK: - 内置预设
enum BuiltInPreset: String, CaseIterable, Identifiable {
    case original, vivid, warm, cool, noir, vintage, cinematic, fade
    var id: Self { self }

    var name: String {
        switch self {
        case .original: return "原始"
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
        case .original: return 100; case .vivid: return 110; case .warm: return 105
        case .cool: return 95; case .noir: return 100; case .vintage: return 95
        case .cinematic: return 90; case .fade: return 110
        }
    }
    var contrast: Double {
        switch self {
        case .original: return 100; case .vivid: return 120; case .warm: return 105
        case .cool: return 100; case .noir: return 130; case .vintage: return 90
        case .cinematic: return 115; case .fade: return 85
        }
    }
    var saturation: Double {
        switch self {
        case .original: return 100; case .vivid: return 150; case .warm: return 110
        case .cool: return 90; case .noir: return 0; case .vintage: return 70
        case .cinematic: return 85; case .fade: return 60
        }
    }
    var hue: Double {
        switch self {
        case .original: return 0; case .vivid: return 0; case .warm: return 15
        case .cool: return -15; case .noir: return 0; case .vintage: return 10
        case .cinematic: return -5; case .fade: return 0
        }
    }
    var blur: Double { 0 }
    var grain: Double {
        switch self {
        case .vintage: return 25; case .cinematic: return 10; case .fade: return 15
        default: return 0
        }
    }
    var vignette: Double {
        switch self {
        case .noir: return 40; case .vintage: return 30; case .cinematic: return 50
        default: return 0
        }
    }
    var grayscale: Double {
        switch self {
        case .noir: return 100; default: return 0
        }
    }
    var invert: Double { 0 }
}

private struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    func makeNSView(context: Context) -> NSVisualEffectView { let v = NSVisualEffectView(); v.material = material; v.blendingMode = blendingMode; v.state = .active; return v }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) { }
}
