import SwiftUI
import AppKit

enum LabTab: Int, CaseIterable, Identifiable {
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

enum LabWeatherScene: String, CaseIterable, Identifiable {
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

enum LabParticleLayer: String, CaseIterable, Identifiable {
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

let labParticleMaterials = ParticleMaterial.allCases

struct DetailStudioPanel: View {
    @Binding var isStudioActive: Bool
    @Binding var studioTab: Int
    @Binding var exposure: Double
    @Binding var contrast: Double
    @Binding var saturation: Double
    @Binding var hue: Double
    @Binding var blur: Double
    @Binding var grain: Double
    @Binding var vignette: Double
    @Binding var grayscale: Double
    @Binding var invert: Double
    @Binding var highlights: Double
    @Binding var shadows: Double
    @Binding var dispersion: Double
    @Binding var currentPresetName: String
    @Binding var particleStyle: String
    @Binding var particleRate: Double
    @Binding var particleLifetime: Double
    @Binding var particleSize: Double
    @Binding var particleGravity: Double
    @Binding var particleTurbulence: Double
    @Binding var particleSpin: Double
    @Binding var particleThrust: Double
    @Binding var particleAngle: Double
    @Binding var particleSpread: Double
    @Binding var particleFadeIn: Double
    @Binding var particleFadeOut: Double
    @Binding var particleColorStart: Color
    @Binding var particleColorEnd: Color
    @Binding var weatherWind: Double
    @Binding var weatherRain: Double
    @Binding var weatherThunder: Double
    @Binding var weatherSnow: Double
    @Binding var studioIntensity: Double
    @Binding var isExpertExpanded: Bool
    @Binding var activeWeatherScene: LabWeatherScene
    @Binding var activeParticleLayer: LabParticleLayer

    let onApplySmartPreset: (BuiltInPreset) -> Void
    let onApplyWeatherScene: (LabWeatherScene) -> Void
    let onApplyParticleLayer: (LabParticleLayer) -> Void
    let onApplyStudioIntensity: (Double) -> Void
    let onReset: () -> Void
    let onSave: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            studioRail
                .frame(width: 104)
                .background(
                    LinearGradient(
                        colors: [Color.white.opacity(0.035), Color.white.opacity(0.012)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            Divider()
                .frame(width: 1)
                .opacity(0.1)

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
            .frame(width: 456)
        }
        .frame(width: 560, height: 588)
        .background(
            ZStack {
                LiquidGlassColors.elevatedBackground.opacity(0.96)
                LinearGradient(
                    colors: [
                        LiquidGlassColors.primaryPink.opacity(0.08),
                        Color.clear,
                        Color.black.opacity(0.18)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Color.white.opacity(0.14), lineWidth: 0.5)
        )
        .artisanShadow(color: .black.opacity(0.52), radius: 58, y: 24)
    }

    private var studioRail: some View {
        VStack(spacing: 12) {
            Text("STUDIO")
                .font(.system(size: 11, weight: .black))
                .kerning(1.8)
                .foregroundStyle(LiquidGlassColors.primaryPink)
                .padding(.top, 24)
                .padding(.bottom, 4)

            Text("LAB")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .kerning(1.8)
                .foregroundStyle(.white.opacity(0.26))
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
            .foregroundStyle(isSelected ? .black.opacity(0.86) : .white.opacity(0.34))
            .frame(width: 76, height: 68)
            .background {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(isSelected ? LiquidGlassColors.primaryPink : Color.clear)
                    .shadow(color: isSelected ? LiquidGlassColors.primaryPink.opacity(0.22) : .clear, radius: 14, x: 0, y: 8)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(isSelected ? Color.white.opacity(0.16) : Color.clear, lineWidth: 0.5)
            }
        }
        .buttonStyle(.plain)
    }

    private var studioHeader: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 7) {
                Text("LIVE CONTROL")
                    .font(.system(size: 10, weight: .black))
                    .kerning(1.8)
                    .foregroundStyle(LiquidGlassColors.primaryPink.opacity(0.78))
                Text(selectedLabTab.headerTitle)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
                Text(selectedLabTab.subtitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.42))
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
        .padding(.horizontal, 24)
        .padding(.vertical, 22)
        .background(Color.black.opacity(0.08))
        .border(width: 0.5, edges: [.bottom], color: .white.opacity(0.08))
    }

    private var selectedLabTab: LabTab {
        LabTab(rawValue: studioTab) ?? .smart
    }

    private var compactDialColumns: [GridItem] {
        [
            GridItem(.fixed(190), spacing: 20),
            GridItem(.fixed(190), spacing: 20)
        ]
    }

    private var intensityBinding: Binding<Double> {
        Binding(
            get: { studioIntensity },
            set: { newValue in
                studioIntensity = newValue
                onApplyStudioIntensity(newValue)
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
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.black.opacity(0.18)))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.white.opacity(0.09), lineWidth: 0.5))
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
            Button(action: onReset) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white.opacity(0.32))
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(Color.black.opacity(0.16)))
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
                    .background(Capsule().fill(isExpertExpanded ? LiquidGlassColors.primaryPink.opacity(0.12) : Color.black.opacity(0.15)))
                    .overlay(Capsule().stroke(isExpertExpanded ? LiquidGlassColors.primaryPink.opacity(0.28) : Color.white.opacity(0.08), lineWidth: 0.5))
            }
            .buttonStyle(.plain)

            Button(action: onSave) {
                Image(systemName: "checkmark")
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(.black)
                    .frame(width: 42, height: 42)
                    .background(Circle().fill(LiquidGlassColors.primaryPink))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color.black.opacity(0.08))
        .border(width: 0.5, edges: [.top], color: .white.opacity(0.08))
    }

    private func sectionKicker(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .black))
            .kerning(1.3)
            .foregroundStyle(.white.opacity(0.34))
    }

    private func lookButton(_ preset: BuiltInPreset) -> some View {
        let isActive = currentPresetName == preset.name
        return Button {
            onApplySmartPreset(preset)
        } label: {
            Text(preset.name)
                .font(.system(size: 13, weight: .bold))
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(isActive ? LiquidGlassColors.primaryPink.opacity(0.16) : Color.black.opacity(0.16))
                .foregroundStyle(isActive ? LiquidGlassColors.primaryPink : .white.opacity(0.55))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(isActive ? LiquidGlassColors.primaryPink.opacity(0.35) : Color.white.opacity(0.08), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }

    private func weatherSceneCard(_ scene: LabWeatherScene) -> some View {
        let isActive = activeWeatherScene == scene
        return Button {
            onApplyWeatherScene(scene)
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
            .foregroundStyle(isActive ? LiquidGlassColors.primaryPink : .white.opacity(0.56))
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 88, alignment: .topLeading)
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(isActive ? LiquidGlassColors.primaryPink.opacity(0.1) : Color.black.opacity(0.16)))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(isActive ? LiquidGlassColors.primaryPink.opacity(0.3) : Color.white.opacity(0.08), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }

    private func layerCard(_ layer: LabParticleLayer) -> some View {
        let isActive = activeParticleLayer == layer
        return Button {
            onApplyParticleLayer(layer)
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
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(isActive ? LiquidGlassColors.primaryPink.opacity(0.1) : Color.black.opacity(0.16)))
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
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(isActive ? LiquidGlassColors.primaryPink.opacity(0.1) : Color.black.opacity(0.16)))
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
            for index in 0..<9 {
                let seed = Double(index)
                let point = CGPoint(
                    x: size.width * (0.22 + 0.56 * (sin(seed * 31.7) * 0.5 + 0.5)),
                    y: size.height * (0.22 + 0.56 * (cos(seed * 17.4) * 0.5 + 0.5))
                )
                let radius = CGFloat(1.2 + (sin(seed * 9.1) * 0.5 + 0.5) * 1.8)
                context.fill(
                    Path(ellipseIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)),
                    with: .color(accent.opacity(0.22 + seed.truncatingRemainder(dividingBy: 3) * 0.08))
                )
            }
        case .glow:
            var glow = context
            glow.addFilter(.blur(radius: 5))
            glow.fill(Path(ellipseIn: CGRect(x: center.x - 12, y: center.y - 12, width: 24, height: 24)), with: .color(accent.opacity(0.42)))
            context.fill(Path(ellipseIn: CGRect(x: center.x - 3, y: center.y - 3, width: 6, height: 6)), with: .color(.white.opacity(0.72)))
        case .bokeh:
            for index in 0..<3 {
                let rect = CGRect(x: 6 + CGFloat(index) * 8, y: 8 + CGFloat(index % 2) * 10, width: 14 + CGFloat(index) * 3, height: 14 + CGFloat(index) * 3)
                var soft = context
                soft.addFilter(.blur(radius: 2.5))
                soft.fill(Path(ellipseIn: rect), with: .color(accent.opacity(0.16)))
                context.stroke(Path(ellipseIn: rect.insetBy(dx: 2, dy: 2)), with: .color(.white.opacity(0.16)), lineWidth: 0.7)
            }
        case .petal:
            for index in 0..<3 {
                var copy = context
                copy.translateBy(x: 11 + CGFloat(index) * 8, y: 14 + CGFloat(index % 2) * 6)
                copy.rotate(by: .degrees(Double(index) * 28 - 18))
                copy.fill(Self.petalPath(width: 15 + CGFloat(index) * 2, height: 7), with: .color(accent.opacity(0.52)))
            }
        case .shard:
            for index in 0..<4 {
                let x = CGFloat(8 + index * 7)
                var path = Path()
                path.move(to: CGPoint(x: x, y: 23 - CGFloat(index % 2) * 8))
                path.addLine(to: CGPoint(x: x + 7, y: 15 - CGFloat(index % 2) * 8))
                context.stroke(path, with: .color(accent.opacity(0.54)), lineWidth: 1.4)
            }
        case .ember:
            var glow = context
            glow.addFilter(.blur(radius: 4))
            glow.fill(Path(ellipseIn: CGRect(x: 9, y: 13, width: 20, height: 12)), with: .color(Color.orange.opacity(0.46)))
            context.fill(Path(ellipseIn: CGRect(x: 15, y: 17, width: 8, height: 5)), with: .color(Color.orange.opacity(0.9)))
        case .snow:
            for index in 0..<6 {
                let seed = Double(index)
                let radius = CGFloat(2.0 + seed.truncatingRemainder(dividingBy: 3))
                let point = CGPoint(x: 8 + CGFloat(index * 5), y: 11 + CGFloat(Int(seed * 7) % 17))
                context.fill(Path(ellipseIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)), with: .color(.white.opacity(0.5)))
            }
        case .rain:
            for index in 0..<5 {
                let x = CGFloat(8 + index * 6)
                var path = Path()
                path.move(to: CGPoint(x: x + 7, y: 7))
                path.addLine(to: CGPoint(x: x, y: 31))
                context.stroke(path, with: .color(accent.opacity(0.46)), lineWidth: 1.2)
            }
        case .mist:
            for index in 0..<3 {
                var mist = context
                mist.addFilter(.blur(radius: 5))
                let rect = CGRect(x: 5 + CGFloat(index) * 6, y: 13 + CGFloat(index % 2) * 3, width: 19, height: 12)
                mist.fill(Path(ellipseIn: rect), with: .color(.white.opacity(0.18)))
            }
        case .firefly:
            for index in 0..<3 {
                let point = CGPoint(x: 12 + CGFloat(index * 8), y: 13 + CGFloat((index * 7) % 14))
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
