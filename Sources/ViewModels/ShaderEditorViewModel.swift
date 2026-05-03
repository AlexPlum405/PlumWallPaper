// Sources/ViewModels/ShaderEditorViewModel.swift
import Foundation
import Observation
import Metal
import SwiftData

@Observable
@MainActor
final class ShaderEditorViewModel {

    // MARK: - State

    var preset: ShaderPreset?
    var passes: [ShaderPassConfig] = []
    var selectedPassIndex: Int?
    var isLivePreview: Bool = true
    var isDirty: Bool = false
    private var modelContext: ModelContext?

    // MARK: - Init

    init() {
        loadDefaultPasses()
    }

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Actions

    func loadDefaultPasses() {
        let filterDefs: [(String, String, [String: ShaderParameterValue])] = [
            ("曝光调整", "exposureFilter", ["exposure": .float(0)]),
            ("对比度", "contrastFilter", ["contrast": .float(1)]),
            ("饱和度", "saturationFilter", ["saturation": .float(1)]),
            ("色调旋转", "hueFilter", ["hue": .float(0)]),
            ("灰度", "grayscaleFilter", ["intensity": .float(0)]),
            ("反转", "invertFilter", ["intensity": .float(0)]),
            ("暗角", "vignetteFilter", ["intensity": .float(0)]),
        ]

        passes = filterDefs.map { (name, _, params) in
            ShaderPassConfig(id: UUID(), type: .filter, name: name, enabled: false, parameters: params)
        }
    }

    func load(_ preset: ShaderPreset) {
        self.preset = preset
        self.passes = preset.passes
        self.isDirty = false
        self.selectedPassIndex = passes.isEmpty ? nil : 0
    }

    func addPass(type: ShaderPassType, name: String) {
        let pass = ShaderPassConfig(id: UUID(), type: type, name: name, enabled: true, parameters: [:])
        passes.append(pass)
        selectedPassIndex = passes.count - 1
        isDirty = true
    }

    func removePass(at index: Int) {
        guard passes.indices.contains(index) else { return }
        passes.remove(at: index)
        if let selected = selectedPassIndex, selected >= passes.count {
            selectedPassIndex = passes.isEmpty ? nil : passes.count - 1
        }
        isDirty = true
    }

    func togglePass(at index: Int) {
        guard passes.indices.contains(index) else { return }
        passes[index].enabled.toggle()
        isDirty = true
        if isLivePreview {
            applyToEngine()
        }
    }

    func updateParameter(passIndex: Int, key: String, value: ShaderParameterValue) {
        guard passes.indices.contains(passIndex) else { return }
        passes[passIndex].parameters[key] = value
        isDirty = true
        if isLivePreview {
            applyToEngine()
        }
    }

    func applyToEngine(screenId: String? = nil) {
        let enabledPasses = passes.filter(\.enabled)
        guard !enabledPasses.isEmpty else {
            RenderPipeline.shared.updateEnvironmentEffects(nil)
            return
        }

        var effects = WallpaperRenderEffects.identity
        effects.name = preset?.name ?? "Shader Editor"

        for pass in enabledPasses {
            switch pass.name {
            case "曝光调整":
                effects.exposure = Double(pass.float("exposure", default: 0)) * 100 + 100
            case "对比度":
                effects.contrast = Double(pass.float("contrast", default: 1)) * 100
            case "饱和度":
                effects.saturation = Double(pass.float("saturation", default: 1)) * 100
            case "色调旋转":
                effects.hue = Double(pass.float("hue", default: 0))
            case "灰度":
                effects.grayscale = Double(pass.float("intensity", default: 0)) * 100
            case "反转":
                effects.invert = Double(pass.float("intensity", default: 0)) * 100
            case "暗角":
                effects.vignette = Double(pass.float("intensity", default: 0)) * 100
            default:
                break
            }
        }

        RenderPipeline.shared.updateEnvironmentEffects(effects.hasVisualAdjustments || effects.hasDynamicEnvironment ? effects : nil)
    }

    func save(name: String = "全局暗房预设") {
        if preset == nil {
            let newPreset = ShaderPreset(name: name)
            modelContext?.insert(newPreset)
            preset = newPreset
        }

        guard let preset else { return }
        preset.passes = passes
        try? modelContext?.save()
        isDirty = false
    }

    func revert() {
        guard let preset else { return }
        passes = preset.passes
        isDirty = false
    }
}

private extension ShaderPassConfig {
    func float(_ key: String, default defaultValue: Float) -> Float {
        guard let value = parameters[key] else { return defaultValue }
        switch value {
        case .float(let number):
            return number
        case .int(let number):
            return Float(number)
        default:
            return defaultValue
        }
    }
}
