// Sources/ViewModels/ShaderEditorViewModel.swift
import Foundation
import Observation
import Metal

@Observable
@MainActor
final class ShaderEditorViewModel {

    // MARK: - State

    var preset: ShaderPreset?
    var passes: [ShaderPassConfig] = []
    var selectedPassIndex: Int?
    var isLivePreview: Bool = true
    var isDirty: Bool = false

    // MARK: - Init

    init() {
        loadDefaultPasses()
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
        // TODO: 将当前 passes 配置同步到 RenderPipeline 的 ShaderGraph
        // RenderPipeline.shared.updateShaderPreset(passes, screenId: screenId)
    }

    func save() {
        guard let preset else { return }
        preset.passes = passes
        isDirty = false
        // TODO: persist via ModelContext.save()
    }

    func revert() {
        guard let preset else { return }
        passes = preset.passes
        isDirty = false
    }
}
