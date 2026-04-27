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
    
    init(wallpaper: Wallpaper) {
        self.wallpaper = wallpaper
        // 从已有的 FilterPreset 初始化，或者默认值
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
        HStack(spacing: 0) {
            // --- 全屏预览区 ---
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                // 实时预览（此处应接渲染引擎，暂时用原图占位）
                if let thumbData = try? Data(contentsOf: URL(fileURLWithPath: wallpaper.thumbnailPath)),
                   let nsImage = NSImage(data: thumbData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .blur(radius: blur / 2) // 简单的 UI 层模拟
                        .grayscale(grayscale / 100)
                        .brightness((exposure - 100) / 200)
                        .contrast(contrast / 100)
                        .saturation(saturation / 100)
                        .hueRotation(.degrees(hue))
                }
                
                // 顶部关闭按钮
                VStack {
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 20, weight: .bold))
                                .padding(12)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        Spacer()
                    }
                    .padding(32)
                    Spacer()
                }
            }
            
            // --- 右侧调色面板 ---
            VStack(alignment: .leading, spacing: 32) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("色彩调节")
                        .font(Theme.Fonts.display(size: 24))
                        .italic()
                    Text(wallpaper.name)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.3))
                }
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 40) {
                        // 预设选择器
                        AdjustGroup(label: "预设 (PRESETS)") {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    PresetItem(name: "默认", icon: "circle.fill", isActive: true)
                                    PresetItem(name: "胶片", icon: "camera.filters")
                                    PresetItem(name: "深夜", icon: "moon.fill")
                                    PresetItem(name: "复古", icon: "archivebox.fill")
                                }
                            }
                        }
                        
                        AdjustGroup(label: "基础校正") {
                            AdjustRow(label: "曝光度", value: $exposure, range: 0...200)
                            AdjustRow(label: "对比度", value: $contrast, range: 0...200)
                            AdjustRow(label: "饱和度", value: $saturation, range: 0...200)
                            AdjustRow(label: "色调", value: $hue, range: -180...180)
                        }
                        
                        AdjustGroup(label: "特效") {
                            AdjustRow(label: "模糊", value: $blur, range: 0...20)
                            AdjustRow(label: "颗粒感", value: $grain, range: 0...100)
                            AdjustRow(label: "暗角", value: $vignette, range: 0...100)
                            AdjustRow(label: "黑白", value: $grayscale, range: 0...100)
                        }
                    }
                }
                
                // 操作按钮
                HStack(spacing: 12) {
                    Button(action: resetToDefault) {
                        Text("重置")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Theme.glassHeavy)
                            .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: applyFilter) {
                        Text("应用修改")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.white)
                            .foregroundColor(.black)
                            .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .frame(width: 360)
            .padding(32)
            .background(Color(red: 17/255, green: 18/255, blue: 22/255))
            .border(width: 1, edges: [.leading], color: Theme.border)
        }
    }
    
    // --- 逻辑处理 ---
    
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
            exposure = 100
            contrast = 100
            saturation = 100
            hue = 0
            blur = 0
            grain = 0
            vignette = 0
            grayscale = 0
            invert = 0
        }
    }
}

struct PresetItem: View {
    let name: String
    let icon: String
    var isActive: Bool = false
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isActive ? Theme.accent.opacity(0.1) : Color.white.opacity(0.05))
                    .frame(width: 64, height: 64)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(isActive ? Theme.accent : Color.clear, lineWidth: 2))
                
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(isActive ? Theme.accent : .white.opacity(0.5))
            }
            Text(name)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(isActive ? .white : .white.opacity(0.3))
        }
    }
}
