import SwiftUI
import SwiftData

struct ColorAdjustView: View {
    let wallpaper: Wallpaper
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppViewModel.self) private var viewModel
    
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
    
    @State private var selectedPreset = "DEFAULT"
    @State private var isApplyGlow = false
    
    init(wallpaper: Wallpaper) {
        self.wallpaper = wallpaper
        if let preset = wallpaper.filterPreset {
            _exposure = State(initialValue: preset.exposure)
            _contrast = State(initialValue: preset.contrast)
            _saturation = State(initialValue: preset.saturation)
            _hue = State(initialValue: preset.hue)
            _blur = State(initialValue: preset.blur)
            _grain = State(initialValue: preset.grain)
            _vignette = State(initialValue: preset.vignette)
            _grayscale = State(initialValue: preset.grayscale)
            _invert = State(initialValue: preset.invert)
        }
    }
    
    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                // --- 1. 左侧 75% 预览层 (沉浸式) ---
                ZStack(alignment: .topLeading) {
                    Theme.bg.edgesIgnoringSafeArea(.all)
                    
                    if let nsImage = NSImage(contentsOfFile: wallpaper.filePath) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geo.size.width * 0.75, height: geo.size.height)
                            .clipped()
                            .blur(radius: blur / 2)
                            .grayscale(grayscale / 100)
                            .brightness((exposure - 100) / 400) 
                            .contrast(contrast / 100)
                            .saturation(saturation / 100)
                            .hueRotation(.degrees(hue))
                            .overlay(Color.black.opacity(0.1))
                    }
                    
                    // 原型中的悬浮圆形返回按钮
                    Button(action: { dismiss() }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 48, height: 48)
                            .background(VisualEffectView(material: .hudWindow).clipShape(Circle()))
                            .overlay(Circle().stroke(Theme.border, lineWidth: 1))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(40)
                }
                .frame(width: geo.size.width * 0.75)
                
                // --- 2. 右侧 25% 调节面板 (100% 原型风格) ---
                VStack(spacing: 0) {
                    // 面板头部
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Jewel Customizer ·")
                            .font(Theme.Fonts.ui(size: 12, weight: .bold))
                            .tracking(3)
                            .foregroundColor(Theme.accent)
                        
                        Text("色彩调节")
                            .font(Theme.Fonts.display(size: 42))
                            .italic()
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Text(wallpaper.name.uppercased())
                            .font(Theme.Fonts.ui(size: 11, weight: .semibold))
                            .tracking(2)
                            .opacity(0.3)
                    }
                    .padding(.bottom, 48)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 54) {
                            // 预设
                            AdjustGroup(label: "Filter Presets") {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        PresetCard(name: "DEFAULT", icon: "sparkles", isActive: selectedPreset == "DEFAULT") { selectPreset("DEFAULT") }
                                        PresetCard(name: "CINEMATIC", icon: "camera.fill", isActive: selectedPreset == "CINEMATIC") { selectPreset("CINEMATIC") }
                                        PresetCard(name: "NOIR", icon: "moon.stars.fill", isActive: selectedPreset == "NOIR") { selectPreset("NOIR") }
                                        PresetCard(name: "VINTAGE", icon: "clock.fill", isActive: selectedPreset == "VINTAGE") { selectPreset("VINTAGE") }
                                    }
                                }
                            }
                            
                            // 基础
                            AdjustGroup(label: "Exposure & Contrast") {
                                AdjustRow(label: "曝光度", value: $exposure, range: 0...200)
                                AdjustRow(label: "对比度", value: $contrast, range: 0...200)
                                AdjustRow(label: "饱和度", value: $saturation, range: 0...200)
                                AdjustRow(label: "色调旋转", value: $hue, range: -180...180)
                            }
                            
                            // 细节
                            AdjustGroup(label: "Atmosphere & Grain") {
                                AdjustRow(label: "模糊度", value: $blur, range: 0...20)
                                AdjustRow(label: "暗角强度", value: $vignette, range: 0...100)
                                AdjustRow(label: "黑白映射", value: $grayscale, range: 0...100)
                            }
                        }
                    }
                    
                    Spacer().frame(height: 48)
                    
                    // 底部操作
                    HStack(spacing: 16) {
                        Button(action: resetToDefault) {
                            Text("RESET")
                                .font(Theme.Fonts.ui(size: 12, weight: .bold))
                                .tracking(2)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Theme.glassHeavy)
                                .cornerRadius(12)
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.glassBorder, lineWidth: 1))
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: applyFilter) {
                            Text("APPLY CHANGES")
                                .font(Theme.Fonts.ui(size: 12, weight: .bold))
                                .tracking(2)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.white)
                                .foregroundColor(.black)
                                .cornerRadius(12)
                                .shadow(color: Theme.accent.opacity(isApplyGlow ? 0.4 : 0.15), radius: 20)
                                .onAppear {
                                    withAnimation(.easeInOut(duration: 2).repeatForever()) {
                                        isApplyGlow = true
                                    }
                                }
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(48)
                .frame(width: geo.size.width * 0.25)
                .background(
                    VisualEffectView(material: .underWindowBackground, blendingMode: .withinWindow)
                        .overlay(Color(hex: "0D0E12").opacity(0.4))
                )
                .overlay(
                    Rectangle()
                        .fill(Theme.glassBorder)
                        .frame(width: 1)
                    , alignment: .leading
                )
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
    
    // --- 逻辑 ---
    
    func selectPreset(_ name: String) {
        selectedPreset = name
        withAnimation(.easeInOut) {
            switch name {
            case "CINEMATIC":
                exposure = 110; contrast = 120; saturation = 85; blur = 0; grayscale = 0
            case "NOIR":
                exposure = 90; contrast = 150; saturation = 0; blur = 0; grayscale = 100
            case "VINTAGE":
                exposure = 105; contrast = 90; saturation = 70; blur = 2; grayscale = 10
            default:
                resetToDefault()
            }
        }
    }
    
    func applyFilter() {
        let preset = wallpaper.filterPreset ?? FilterPreset(name: "Custom")
        preset.exposure = exposure
        preset.contrast = contrast
        preset.saturation = saturation
        preset.hue = hue
        preset.blur = blur
        preset.grain = grain
        preset.vignette = vignette
        preset.grayscale = grayscale
        preset.invert = invert
        
        wallpaper.filterPreset = preset
        try? modelContext.save()
        viewModel.applyFilter(preset, to: wallpaper)
        dismiss()
    }
    
    func resetToDefault() {
        withAnimation {
            exposure = 100; contrast = 100; saturation = 100; hue = 0
            blur = 0; grain = 0; vignette = 0; grayscale = 0; invert = 0
            selectedPreset = "DEFAULT"
        }
    }
}

struct PresetCard: View {
    let name: String
    let icon: String
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isActive ? Theme.accent : Theme.glass)
                        .frame(width: 80, height: 80)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.glassBorder, lineWidth: 1))
                    
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(isActive ? .white : .white.opacity(0.3))
                }
                
                Text(name)
                    .font(Theme.Fonts.ui(size: 9, weight: .bold))
                    .tracking(1)
                    .foregroundColor(isActive ? .white : .white.opacity(0.3))
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
