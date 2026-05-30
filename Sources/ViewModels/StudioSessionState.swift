import SwiftUI

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

@MainActor
final class StudioSessionState: ObservableObject {
    @Published var isStudioActive = false
    @Published var studioTab = 0
    @Published var exposure: Double = 100
    @Published var contrast: Double = 100
    @Published var saturation: Double = 100
    @Published var hue: Double = 0
    @Published var blur: Double = 0
    @Published var grain: Double = 0
    @Published var vignette: Double = 0
    @Published var grayscale: Double = 0
    @Published var invert: Double = 0
    @Published var highlights: Double = 100
    @Published var shadows: Double = 100
    @Published var dispersion: Double = 0
    @Published var currentPresetName = "原图"

    @Published var particleStyle = ParticleMaterial.dust.rawValue
    @Published var particleRate: Double = 0
    @Published var particleLifetime: Double = 3
    @Published var particleSize: Double = 4
    @Published var particleGravity: Double = 9.8
    @Published var particleTurbulence: Double = 2
    @Published var particleSpin: Double = 0
    @Published var particleThrust: Double = 0
    @Published var particleAngle: Double = 0
    @Published var particleSpread: Double = 360
    @Published var particleFadeIn: Double = 10
    @Published var particleFadeOut: Double = 30
    @Published var particleColorStart = Color.white
    @Published var particleColorEnd = LiquidGlassColors.primaryPink

    @Published var weatherWind: Double = 0
    @Published var weatherRain: Double = 0
    @Published var weatherThunder: Double = 0
    @Published var weatherSnow: Double = 0

    @Published var studioIntensity: Double = 0
    @Published var isExpertExpanded = false
    @Published var activeWeatherScene: LabWeatherScene = .dust
    @Published var activeParticleLayer: LabParticleLayer = .middle

    var renderEffects: WallpaperRenderEffects {
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

    var shaderPasses: [ShaderPassConfig] {
        let effects = renderEffects
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

    func applyPreset(_ preset: BuiltInPreset) {
        NSLog("[StudioSessionState] 应用预设: \(preset.name)")
        withAnimation(.easeInOut(duration: 0.2)) {
            currentPresetName = preset.name
            exposure = preset.exposure
            contrast = preset.contrast
            saturation = preset.saturation
            hue = preset.hue
            blur = preset.blur
            grain = preset.grain
            vignette = preset.vignette
            grayscale = preset.grayscale
            invert = preset.invert
        }
    }

    func resetFilters() {
        applyPreset(.original)
        withAnimation(.gallerySpring) {
            particleRate = 0
            particleLifetime = 3
            particleSize = 4
            particleGravity = 9.8
            particleTurbulence = 2
            particleSpin = 0
            particleThrust = 0
            particleAngle = 0
            particleSpread = 360
            particleColorStart = .white
            particleColorEnd = LiquidGlassColors.primaryPink
            particleStyle = ParticleMaterial.dust.rawValue
        }
    }

    func resetSession() {
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

    func applySmartPreset(_ preset: BuiltInPreset) {
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

    func applyWeatherScene(_ scene: LabWeatherScene) {
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

    func applyParticleLayer(_ layer: LabParticleLayer) {
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

    func applyStudioIntensity(_ value: Double) {
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

    func loadSavedPreset(from wallpaper: Wallpaper) {
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
