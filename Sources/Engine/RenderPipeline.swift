// Sources/Engine/RenderPipeline.swift
import Foundation
import AppKit
import AVFoundation
import CoreImage
import CoreImage.CIFilterBuiltins

enum ParticleMaterial: String, CaseIterable, Codable, Equatable, Identifiable {
    case dust
    case glow
    case bokeh
    case petal
    case shard
    case ember
    case snow
    case rain
    case mist
    case firefly

    var id: String { rawValue }

    init(style: String?) {
        guard let style else {
            self = .dust
            return
        }
        if let material = ParticleMaterial(rawValue: style) {
            self = material
            return
        }
        switch style {
        case "flower.fill", "leaf.fill":
            self = .petal
        case "drop.fill":
            self = .rain
        case "snowflake":
            self = .snow
        case "sparkle", "sparkles", "star.fill", "sun.max.fill":
            self = .shard
        case "aqi.medium":
            self = .mist
        default:
            self = .dust
        }
    }

    static func legacyMaterial(for index: Int) -> ParticleMaterial? {
        let legacyStyles = [
            "circle.fill",
            "sparkle",
            "sparkles",
            "star.fill",
            "aqi.medium",
            "sun.max.fill",
            "leaf.fill",
            "flower.fill",
            "drop.fill",
            "snowflake"
        ]
        guard legacyStyles.indices.contains(index) else { return nil }
        return ParticleMaterial(style: legacyStyles[index])
    }

    var title: String {
        switch self {
        case .dust: return "微尘"
        case .glow: return "柔光点"
        case .bokeh: return "散景"
        case .petal: return "花瓣"
        case .shard: return "光屑"
        case .ember: return "火星"
        case .snow: return "雪粒"
        case .rain: return "雨丝"
        case .mist: return "薄雾"
        case .firefly: return "流萤"
        }
    }

    var detail: String {
        switch self {
        case .dust: return "细小低透明空气颗粒"
        case .glow: return "柔边圆形发光粒"
        case .bokeh: return "大尺寸虚化镜头光斑"
        case .petal: return "不对称弯曲花瓣"
        case .shard: return "短斜线碎光，不是星形"
        case .ember: return "暖色小火星与拖尾"
        case .snow: return "柔边雪点和小团"
        case .rain: return "高速细长透明雨线"
        case .mist: return "半透明模糊雾团"
        case .firefly: return "亮核加外圈微光"
        }
    }

    var previewDensityMultiplier: Double {
        switch self {
        case .bokeh, .mist: return 0.28
        case .petal, .ember, .firefly: return 0.6
        case .rain: return 1.35
        default: return 1.0
        }
    }

    var previewSizeMultiplier: Double {
        switch self {
        case .dust: return 0.55
        case .glow: return 1.1
        case .bokeh: return 3.6
        case .petal: return 2.8
        case .shard: return 1.8
        case .ember: return 1.35
        case .snow: return 1.0
        case .rain: return 1.0
        case .mist: return 5.8
        case .firefly: return 1.45
        }
    }

    var previewFootprintMultiplier: Double {
        switch self {
        case .petal: return 1.85
        case .shard: return 1.44
        case .ember: return 1.1
        case .rain: return 2.6
        case .mist: return 1.9
        case .firefly: return 1.4
        default: return 1.0
        }
    }

    var desktopSpriteReferenceSize: Double {
        switch self {
        case .dust: return 18
        case .glow: return 52
        case .bokeh: return 74
        case .petal: return 52
        case .shard: return 34
        case .ember: return 28
        case .snow: return 24
        case .rain: return 66
        case .mist: return 100
        case .firefly: return 36
        }
    }
}

struct WallpaperRenderEffects: Codable, Equatable {
    var name: String
    var exposure: Double
    var contrast: Double
    var saturation: Double
    var hue: Double
    var blur: Double
    var grain: Double
    var vignette: Double
    var grayscale: Double
    var invert: Double
    var highlights: Double
    var shadows: Double
    var dispersion: Double
    var weatherWind: Double
    var weatherRain: Double
    var weatherThunder: Double
    var weatherSnow: Double
    var particleStyle: String
    var particleRate: Double
    var particleLifetime: Double
    var particleSize: Double
    var particleGravity: Double
    var particleTurbulence: Double
    var particleSpin: Double
    var particleThrust: Double
    var particleAngle: Double
    var particleSpread: Double
    var particleFadeIn: Double
    var particleFadeOut: Double

    static let identity = WallpaperRenderEffects(
        name: "原图",
        exposure: 100,
        contrast: 100,
        saturation: 100,
        hue: 0,
        blur: 0,
        grain: 0,
        vignette: 0,
        grayscale: 0,
        invert: 0,
        highlights: 100,
        shadows: 100,
        dispersion: 0,
        weatherWind: 0,
        weatherRain: 0,
        weatherThunder: 0,
        weatherSnow: 0,
        particleStyle: ParticleMaterial.dust.rawValue,
        particleRate: 0,
        particleLifetime: 3,
        particleSize: 4,
        particleGravity: 9.8,
        particleTurbulence: 2,
        particleSpin: 0,
        particleThrust: 0,
        particleAngle: 0,
        particleSpread: 360,
        particleFadeIn: 10,
        particleFadeOut: 30
    )

    var hasVisualAdjustments: Bool {
        abs(exposure - 100) > 0.1 ||
        abs(contrast - 100) > 0.1 ||
        abs(saturation - 100) > 0.1 ||
        abs(hue) > 0.1 ||
        blur > 0.1 ||
        grain > 0.1 ||
        vignette > 0.1 ||
        grayscale > 0.1 ||
        invert > 0.1 ||
        abs(highlights - 100) > 0.1 ||
        abs(shadows - 100) > 0.1 ||
        dispersion > 0.1
    }

    var hasDynamicEnvironment: Bool {
        weatherRain > 0.1 ||
        weatherThunder > 0.1 ||
        weatherSnow > 0.1 ||
        particleRate > 0.1
    }
}

enum WallpaperRenderEffectRenderer {
    private static let ciContext = CIContext(options: [.cacheIntermediates: false])

    static func apply(_ effects: WallpaperRenderEffects, to image: CIImage) -> CIImage {
        let extent = image.extent
        var output = image.clampedToExtent()

        let brightness = max(-1, min(1, (effects.exposure - 100) / 100))
        let contrast = max(0, effects.contrast / 100)
        let saturation = max(0, effects.saturation / 100) * max(0, 1 - effects.grayscale / 100)

        let colorControls = CIFilter.colorControls()
        colorControls.inputImage = output
        colorControls.brightness = Float(brightness)
        colorControls.contrast = Float(contrast)
        colorControls.saturation = Float(saturation)
        output = colorControls.outputImage ?? output

        if abs(effects.hue) > 0.1 {
            let hue = CIFilter.hueAdjust()
            hue.inputImage = output
            hue.angle = Float(effects.hue * .pi / 180)
            output = hue.outputImage ?? output
        }

        if effects.invert > 50 {
            let invert = CIFilter.colorInvert()
            invert.inputImage = output
            output = invert.outputImage ?? output
        }

        if effects.blur > 0.1 {
            let blur = CIFilter.gaussianBlur()
            blur.inputImage = output
            blur.radius = Float(min(effects.blur, 40))
            output = (blur.outputImage ?? output).cropped(to: extent)
        }

        if effects.vignette > 0.1 {
            let vignette = CIFilter.vignette()
            vignette.inputImage = output
            vignette.intensity = Float(min(effects.vignette / 36, 2.2))
            vignette.radius = Float(max(extent.width, extent.height) * 0.72)
            output = vignette.outputImage ?? output
        }

        return output.cropped(to: extent)
    }

    static func makeVideoComposition(for url: URL, effects: WallpaperRenderEffects) -> AVVideoComposition? {
        guard effects.hasVisualAdjustments else { return nil }
        let asset = AVURLAsset(url: url)
        return AVVideoComposition(asset: asset) { request in
            let filtered = apply(effects, to: request.sourceImage)
            request.finish(with: filtered, context: nil)
        }
    }

    static func renderImage(sourceURL: URL, effects: WallpaperRenderEffects) throws -> URL {
        guard effects.hasVisualAdjustments else { return sourceURL }
        guard let input = CIImage(contentsOf: sourceURL) else { return sourceURL }

        var output = apply(effects, to: input)
        if effects.grain > 0.1 {
            output = addStillGrain(to: output, amount: effects.grain)
        }

        guard let cgImage = ciContext.createCGImage(output, from: output.extent) else { return sourceURL }
        let bitmap = NSBitmapImageRep(cgImage: cgImage)
        guard let data = bitmap.representation(using: .png, properties: [:]) else { return sourceURL }

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("PlumWallPaper-Lab-\(UUID().uuidString).png")
        try data.write(to: outputURL)
        return outputURL
    }

    private static func addStillGrain(to image: CIImage, amount: Double) -> CIImage {
        let random = CIFilter.randomGenerator().outputImage?.cropped(to: image.extent) ?? image
        let mono = CIFilter.colorControls()
        mono.inputImage = random
        mono.saturation = 0
        mono.contrast = Float(1 + amount / 40)

        let opacity = CIFilter.colorMatrix()
        opacity.inputImage = mono.outputImage ?? random
        opacity.aVector = CIVector(x: 0, y: 0, z: 0, w: min(0.22, amount / 220))

        let blend = CIFilter.overlayBlendMode()
        blend.inputImage = opacity.outputImage ?? random
        blend.backgroundImage = image
        return blend.outputImage ?? image
    }
}

@MainActor
final class RenderPipeline {
    static let shared = RenderPipeline()

    private var renderers: [String: ScreenRenderer] = [:]

    /// 当前全局静音状态（muteAudio 默认语义）
    private(set) var isMuted: Bool = false
    /// 壁纸透明度（0-100）
    private(set) var wallpaperOpacity: Int = 100

    private init() {}

    func setupRenderers() {
        NSLog("[RenderPipeline] setupRenderers 开始，屏幕数量: \(NSScreen.screens.count)")
        for screen in NSScreen.screens {
            let description = screen.deviceDescription
            let screenNumber = description[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber
            let screenId = screenNumber?.stringValue ?? screen.localizedName
            let renderer = ScreenRenderer(screen: screen, screenId: screenId)
            renderers[screenId] = renderer
            NSLog("[RenderPipeline] ✅ 屏幕 \(screenId) 渲染器创建成功")
        }
        NSLog("[RenderPipeline] setupRenderers 完成，渲染器数量: \(renderers.count)")
    }

    func setWallpaper(url: URL, screenId: String? = nil, wallpaperId: UUID? = nil, effects: WallpaperRenderEffects? = nil) async throws {
        NSLog("[RenderPipeline] setWallpaper: \(url.lastPathComponent), 渲染器数量: \(renderers.count)")
        if renderers.isEmpty {
            NSLog("[RenderPipeline] ⚠️ 无可用渲染器，尝试重新初始化...")
            setupRenderers()
        }
        if let screenId = screenId, let renderer = renderers[screenId] {
            NSLog("[RenderPipeline] 设置屏幕 \(screenId) 壁纸")
            try await renderer.setWallpaper(url: url, wallpaperId: wallpaperId, effects: effects)
        } else {
            NSLog("[RenderPipeline] 设置所有屏幕壁纸，共 \(renderers.count) 个")
            for (id, renderer) in renderers {
                NSLog("[RenderPipeline] -> 屏幕 \(id)")
                try await renderer.setWallpaper(url: url, wallpaperId: wallpaperId, effects: effects)
            }
        }
    }

    func setImageWallpaper(url: URL, screenId: String? = nil, wallpaperId: UUID? = nil, effects: WallpaperRenderEffects? = nil) async throws {
        NSLog("[RenderPipeline] setImageWallpaper: \(url.lastPathComponent), 渲染器数量: \(renderers.count)")
        if renderers.isEmpty {
            NSLog("[RenderPipeline] ⚠️ 无可用渲染器，尝试重新初始化...")
            setupRenderers()
        }
        if let screenId = screenId, let renderer = renderers[screenId] {
            NSLog("[RenderPipeline] 设置屏幕 \(screenId) 图片壁纸")
            try await renderer.setImageWallpaper(url: url, wallpaperId: wallpaperId, effects: effects)
        } else {
            NSLog("[RenderPipeline] 设置所有屏幕图片壁纸，共 \(renderers.count) 个")
            for (id, renderer) in renderers {
                NSLog("[RenderPipeline] -> 屏幕 \(id)")
                try await renderer.setImageWallpaper(url: url, wallpaperId: wallpaperId, effects: effects)
            }
        }
    }

    func pauseAll() {
        renderers.values.forEach { $0.pause() }
    }

    func resumeAll() {
        renderers.values.forEach { $0.resume() }
    }

    func updateEnvironmentEffects(_ effects: WallpaperRenderEffects?) {
        if renderers.isEmpty {
            setupRenderers()
        }
        renderers.values.forEach { $0.updateEnvironment(effects: effects) }
    }

    func cleanup() {
        renderers.values.forEach { $0.cleanup() }
        renderers.removeAll()
    }

    // MARK: - 音频控制

    /// 获取每个屏幕的静音状态
    func getAudioMuteStates() -> [String: Bool] {
        var states: [String: Bool] = [:]
        for (id, r) in renderers {
            states[id] = r.isMuted
        }
        return states
    }

    /// 设置静音（可选指定屏幕）
    func setMuted(_ muted: Bool, screenId: String? = nil) {
        if let screenId = screenId, let renderer = renderers[screenId] {
            renderer.setMuted(muted)
        } else {
            isMuted = muted
            renderers.values.forEach { $0.setMuted(muted) }
        }
    }

    // MARK: - 透明度

    func updateWallpaperOpacity(_ opacity: Int) {
        wallpaperOpacity = opacity
        let alpha = CGFloat(max(0, min(100, opacity))) / 100.0
        renderers.values.forEach { $0.setOpacity(alpha) }
    }

    // MARK: - 性能监控

    /// 当前活动壁纸 ID 集合
    var activeWallpaperIds: Set<UUID> {
        Set(renderers.values.compactMap { $0.currentWallpaperId })
    }
}
