import SwiftUI

// MARK: - Artisan Exhibition Hall (Scheme C: Artisan Gallery)
// 沉浸式壁纸鉴赏厅，UI 仅在鼠标触碰功能区时如雾般浮现。

struct WallpaperDetailView: View {
    let wallpaper: Wallpaper
    var onPrevious: (() -> Void)? = nil
    var onNext: (() -> Void)? = nil
    
    @Environment(\.dismiss) private var dismiss
    
    // 感应状态 (精确热区控制)
    @State private var isLeftHovered = false
    @State private var isRightHovered = false
    @State private var isTopHovered = false
    @State private var isBottomHovered = false
    @State private var isCloseButtonHovered = false
    
    @State private var isEditingShaders = false
    @State private var isApplying = false
    @State var isShowingShaderEditor = false
    
    // 显示器选择
    @State private var selectedDisplays: Set<String> = ["built-in"]
    private let mockDisplays = [
        (id: "built-in", name: "内建显示器", icon: "laptopcomputer"),
        (id: "external-1", name: "Studio Display", icon: "display"),
        (id: "external-2", name: "LG UltraFine", icon: "display")
    ]
    
    // 滤镜状态
    @State var exposure: Double = 100
    @State var contrast: Double = 100
    @State var saturation: Double = 100
    @State var hue: Double = 0
    @State var blur: Double = 0
    @State var grain: Double = 0
    @State var vignette: Double = 0
    @State var grayscale: Double = 0
    @State var invert: Double = 0
    @State var currentPresetName: String = "原始"
    
    private let sidebarWidth: CGFloat = 360 // 缩减宽度，更精致
    
    var body: some View {
        ZStack {
            // 1. 底层：全屏画布 (无任何交互干扰)
            fullscreenCanvas
            
            // 2. 交互层：透明拖拽锚点 (支持全窗口拖动)
            Color.clear
                .contentShape(Rectangle())
                .windowDragGesture()
            
            // 3. 左侧：艺术标题
            artisanTitleHUD
                .opacity(isLeftHovered ? 1 : 0)
                .onHover { hovering in withAnimation(.galleryEase) { isLeftHovered = hovering } }
                .padding(.leading, 80)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            
            // 4. 右侧：参数工作室 (悬浮卡片，自带位移与感应)
            artisanSidebarHUD
                .offset(x: isRightHovered ? 0 : 40)
                .opacity(isRightHovered ? 1 : 0)
                .onHover { hovering in withAnimation(.gallerySpring) { isRightHovered = hovering } }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            
            // 5. 顶部：导航箭头
            navArrowHUD(icon: "chevron.up") { onPrevious?() }
                .padding(.top, 40)
                .opacity(isTopHovered ? 0.8 : 0)
                .onHover { hovering in withAnimation(.gallerySpring) { isTopHovered = hovering } }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            
            // 6. 底部：核心动作中心
            artisanActionCenter
                .padding(.bottom, 48)
                .opacity(isBottomHovered ? 1 : 0)
                .onHover { hovering in withAnimation(.gallerySpring) { isBottomHovered = hovering } }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            
            // 7. 全局关闭控制
            closeButtonHUD
        }
        .sheet(isPresented: $isShowingShaderEditor) {
            ShaderEditorView()
        }
        .frame(minWidth: 1200, minHeight: 800)
        .preferredColorScheme(.dark)
    }
    
    // MARK: - A. 视觉子层级
    
    private var fullscreenCanvas: some View {
        ZStack {
            if let url = URL(string: wallpaper.filePath) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable().aspectRatio(contentMode: .fill)
                    } else { Color.black }
                }
            } else { Color.black }
            RadialGradient(colors: [.clear, .black.opacity(0.4)], center: .center, startRadius: 200, endRadius: 1000)
        }.ignoresSafeArea()
    }
    
    private var artisanTitleHUD: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("EXHIBITION CURATED").font(.system(size: 12, weight: .black)).kerning(6).foregroundStyle(LiquidGlassColors.primaryPink)
            VStack(alignment: .leading, spacing: -20) {
                Text(wallpaper.name.prefix(1)).font(.custom("Georgia", size: 160)).foregroundStyle(.white.opacity(0.08)).offset(x: -20, y: 40)
                Text(wallpaper.name).artisanTitleStyle(size: 64, kerning: 2).shadow(color: .black.opacity(0.5), radius: 20)
            }
            HStack(spacing: 24) {
                metadataTag(icon: "ruler", text: wallpaper.resolution ?? "8K")
                metadataTag(icon: "cpu", text: "ULTRA RENDERING")
            }
        }.fixedSize() // 确保热区仅包裹内容
    }
    
    private var artisanSidebarHUD: some View {
        ZStack {
            if isEditingShaders {
                artisanShaderPanel
            } else {
                // 作品详情面板 (悬浮卡片感)
                VStack(alignment: .leading, spacing: 32) {
                    ArtisanHeader(title: "CURATION INFO", subtitle: "作品策展详情")
                    
                    VStack(spacing: 20) {
                        metadataRow(label: "Format", value: wallpaper.type == .video ? "Dynamic" : "Still")
                        metadataRow(label: "Dimension", value: wallpaper.resolution ?? "8K")
                        metadataRow(label: "Size", value: ByteCountFormatter.string(fromByteCount: wallpaper.fileSize, countStyle: .file))
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("GENRE").font(.system(size: 9, weight: .black)).kerning(2).foregroundStyle(LiquidGlassColors.textQuaternary)
                        FlowLayout(spacing: 8) {
                            ForEach(wallpaper.tags) { tag in
                                Text(tag.name).font(.system(size: 10, weight: .bold)).padding(.horizontal, 12).padding(.vertical, 5)
                                    .background(Color.white.opacity(0.05)).clipShape(Capsule())
                                    .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 0.5))
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: { withAnimation(.gallerySpring) { isEditingShaders = true } }) {
                        HStack {
                            Image(systemName: "slider.vertical.3").font(.system(size: 14))
                            Text("ENTER STUDIO").font(.system(size: 11, weight: .black)).kerning(2)
                            Spacer()
                            Image(systemName: "arrow.right").font(.system(size: 10))
                        }
                        .padding(20).background(LiquidGlassColors.primaryPink).clipShape(RoundedRectangle(cornerRadius: 16))
                        .foregroundStyle(.black)
                    }.buttonStyle(.plain)
                }
                .padding(32)
                .background(VisualEffectView(material: .hudWindow, blendingMode: .withinWindow))
                .clipShape(RoundedRectangle(cornerRadius: 32))
                .overlay(RoundedRectangle(cornerRadius: 32).stroke(Color.white.opacity(0.1), lineWidth: 0.5))
                .artisanShadow(color: .black.opacity(0.3), radius: 40)
                .frame(width: 320) 
            }
        }
        .padding(.trailing, 40) 
    }

    private var artisanActionCenter: some View {
        VStack(spacing: 36) {
            HStack(spacing: 32) {
                actionCircleButton(icon: wallpaper.isFavorite ? "heart.fill" : "heart", color: wallpaper.isFavorite ? LiquidGlassColors.primaryPink : .white.opacity(0.6)) { }
                Button(action: {
                    isApplying = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { isApplying = false }
                }) {
                    HStack(spacing: 16) {
                        if isApplying { CustomProgressView(tint: .white, scale: 0.8) }
                        else {
                            Image(systemName: "paintpalette.fill").font(.system(size: 16))
                            Text("应用此作").font(.system(size: 15, weight: .bold)).fixedSize().kerning(2)
                        }
                    }
                    .padding(.horizontal, 48).frame(height: 56).background(Capsule().fill(LiquidGlassColors.primaryPink)).artisanShadow(color: LiquidGlassColors.primaryPink.opacity(0.3))
                }.buttonStyle(.plain)
                actionCircleButton(icon: "arrow.down.to.line.compact", color: .white.opacity(0.6)) { }
            }
            .padding(12).background(.ultraThinMaterial, in: Capsule()).background(Capsule().fill(Color.white.opacity(0.02)))
            .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 0.5))
            
            navArrowHUD(icon: "chevron.down") { onNext?() }
        }.fixedSize() // 重要：感应热区仅限组件物理面积，不再抢占右侧编辑器空间
    }
    
    // MARK: - 辅助组件
    
    private func metadataTag(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 10, weight: .bold))
            Text(text).font(.system(size: 10, weight: .black)).kerning(1)
        }
        .foregroundStyle(.white.opacity(0.4)).padding(.horizontal, 12).padding(.vertical, 6)
        .background(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
    }
    
    private func metadataRow(label: String, value: String) -> some View {
        HStack {
            Text(label).font(.system(size: 12, weight: .bold)).foregroundStyle(LiquidGlassColors.textQuaternary)
            Spacer(); Text(value).font(.system(size: 12, weight: .bold)).foregroundStyle(LiquidGlassColors.textSecondary)
        }
    }

    private func navArrowHUD(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).font(.system(size: 20, weight: .light)).foregroundStyle(.white).frame(width: 60, height: 40)
                .background(.ultraThinMaterial, in: Capsule()).background(Capsule().fill(Color.white.opacity(0.05)))
                .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 0.5))
        }.buttonStyle(.plain)
    }
    
    private func actionCircleButton(icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).font(.system(size: 20)).foregroundStyle(color).frame(width: 56, height: 56)
                .background(Circle().fill(Color.white.opacity(0.05))).overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 0.5))
        }.buttonStyle(.plain)
    }
    
    private var closeButtonHUD: some View {
        VStack {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark").font(.system(size: 16, weight: .light)).frame(width: 48, height: 48)
                        .background(Circle().fill(Color.black.opacity(0.4))).overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 0.5))
                }
                .buttonStyle(.plain).padding(40).opacity(isCloseButtonHovered || isTopHovered || isLeftHovered ? 1 : 0).onHover { isCloseButtonHovered = $0 }
                Spacer()
            }; Spacer()
        }
    }

    private var artisanShaderPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header: 紧凑版
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("LENS STUDIO").font(.system(size: 11, weight: .black)).kerning(2).foregroundStyle(LiquidGlassColors.primaryPink)
                    Text("画面光学调节").font(.system(size: 13, weight: .bold))
                }
                Spacer()
                Button(action: { withAnimation { isEditingShaders = false } }) {
                    Image(systemName: "minus").font(.system(size: 14, weight: .bold)).foregroundStyle(LiquidGlassColors.textQuaternary)
                }.buttonStyle(.plain)
            }
            .padding(.horizontal, 28).padding(.top, 32).padding(.bottom, 24)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    // 1. 预设区 (胶囊网格)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("PRESETS").font(.system(size: 9, weight: .black)).kerning(1.5).foregroundStyle(LiquidGlassColors.textQuaternary)
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            ForEach(BuiltInPreset.allCases) { preset in
                                Button(action: { applyPreset(preset) }) {
                                    Text(preset.name).font(.system(size: 10, weight: .bold))
                                        .frame(maxWidth: .infinity).frame(height: 32)
                                        .background(currentPresetName == preset.name ? LiquidGlassColors.primaryPink : Color.white.opacity(0.05))
                                        .foregroundStyle(currentPresetName == preset.name ? Color.black : LiquidGlassColors.textSecondary)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }.buttonStyle(.plain)
                            }
                        }
                    }
                    
                    // 2. 光学参数组
                    VStack(alignment: .leading, spacing: 20) {
                        ArtisanSubHeader(title: "OPTICAL")
                        artisanInstrumentRow(icon: "sun.max.fill", label: "Exposure", value: $exposure, range: 0...200)
                        artisanInstrumentRow(icon: "circle.lefthalf.filled", label: "Contrast", value: $contrast, range: 50...150)
                        artisanInstrumentRow(icon: "drop.fill", label: "Saturation", value: $saturation, range: 0...200)
                    }
                    
                    // 3. 构图参数组
                    VStack(alignment: .leading, spacing: 20) {
                        ArtisanSubHeader(title: "COMPOSITION")
                        artisanInstrumentRow(icon: "camera.filters", label: "Blur", value: $blur, range: 0...20)
                        artisanInstrumentRow(icon: "scope", label: "Vignette", value: $vignette, range: 0...100)
                    }
                }
                .padding(.horizontal, 28).padding(.bottom, 40)
            }
            
            // 底部操作区 (Fixed & Small)
            HStack(spacing: 12) {
                Button(action: { resetFilters() }) {
                    Image(systemName: "arrow.counterclockwise").font(.system(size: 12))
                        .frame(width: 44, height: 44).background(Color.white.opacity(0.05)).clipShape(Circle())
                }.buttonStyle(.plain)

                Button(action: { openShaderEditor() }) {
                    Text("ADVANCED")
                        .font(.system(size: 10, weight: .black)).kerning(2)
                        .frame(maxWidth: .infinity).frame(height: 44)
                        .background(Capsule().stroke(LiquidGlassColors.tertiaryBlue, lineWidth: 1))
                        .foregroundStyle(LiquidGlassColors.tertiaryBlue)
                }.buttonStyle(.plain)

                Button(action: { /* 保存 */ }) {
                    Image(systemName: "checkmark").font(.system(size: 14, weight: .bold))
                        .frame(width: 44, height: 44).background(LiquidGlassColors.primaryPink).clipShape(Circle()).foregroundStyle(.black)
                }.buttonStyle(.plain)
            }
            .padding(24).background(Color.black.opacity(0.2))
        }
        .frame(width: 320, height: 640) 
        .background(VisualEffectView(material: .hudWindow, blendingMode: .withinWindow))
        .clipShape(RoundedRectangle(cornerRadius: 32))
        .overlay(RoundedRectangle(cornerRadius: 32).stroke(Color.white.opacity(0.12), lineWidth: 0.5))
        .artisanShadow(color: .black.opacity(0.4), radius: 50)
    }
    
    private func artisanInstrumentRow(icon: String, label: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon).font(.system(size: 10)).foregroundStyle(LiquidGlassColors.primaryPink)
                Text(label).font(.system(size: 10, weight: .bold)).foregroundStyle(LiquidGlassColors.textSecondary)
                Spacer()
                Text("\(Int(value.wrappedValue))").font(.system(size: 10, weight: .medium, design: .monospaced)).foregroundStyle(LiquidGlassColors.textQuaternary)
            }
            Slider(value: value, in: range).tint(LiquidGlassColors.primaryPink).controlSize(.mini)
        }
    }
    
    private func artisanFilterGroup<Content: View>(header: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(header).font(.system(size: 11, weight: .black)).kerning(2).foregroundStyle(LiquidGlassColors.textQuaternary)
            VStack(spacing: 24) { content() }.padding(24).galleryCardStyle(radius: 20, padding: 0)
        }
    }
    
    private func artisanSlider(label: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(label).font(.system(size: 12, weight: .bold)).foregroundStyle(LiquidGlassColors.textSecondary)
                Spacer(); Text("\(Int(value.wrappedValue))").font(.system(size: 11, weight: .bold, design: .monospaced)).foregroundStyle(LiquidGlassColors.primaryPink)
            }
            Slider(value: value, in: range).tint(LiquidGlassColors.primaryPink)
        }
    }

    private func artisanDisplayCard(display: (id: String, name: String, icon: String)) -> some View {
        let isSelected = selectedDisplays.contains(display.id)
        return Button {
            withAnimation(.gallerySpring) {
                if selectedDisplays.contains(display.id) { if selectedDisplays.count > 1 { selectedDisplays.remove(display.id) } }
                else { selectedDisplays.insert(display.id) }
            }
        } label: {
            HStack(spacing: 16) {
                Image(systemName: display.icon).font(.system(size: 16)).foregroundStyle(isSelected ? LiquidGlassColors.primaryPink : LiquidGlassColors.textTertiary)
                Text(display.name).font(.system(size: 13, weight: .bold)).foregroundStyle(isSelected ? LiquidGlassColors.textPrimary : LiquidGlassColors.textSecondary)
                Spacer(); if isSelected { Image(systemName: "checkmark.seal.fill").foregroundStyle(LiquidGlassColors.primaryPink) }
            }
            .padding(16).background(RoundedRectangle(cornerRadius: 16).fill(isSelected ? LiquidGlassColors.primaryPink.opacity(0.1) : Color.white.opacity(0.03)))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(isSelected ? LiquidGlassColors.primaryPink.opacity(0.4) : Color.clear, lineWidth: 1))
        }.buttonStyle(.plain)
    }
}

// MARK: - Sub-Components

struct ArtisanSubHeader: View {
    let title: String
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.system(size: 9, weight: .black)).kerning(2).foregroundStyle(LiquidGlassColors.textSecondary)
            Rectangle().frame(width: 20, height: 1).foregroundStyle(LiquidGlassColors.primaryPink)
        }
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
