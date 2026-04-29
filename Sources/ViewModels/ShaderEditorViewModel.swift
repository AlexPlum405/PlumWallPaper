// Sources/ViewModels/ShaderEditorViewModel.swift
import Foundation
import Observation

@Observable
@MainActor
final class ShaderEditorViewModel {

    // MARK: - State

    var preset: ShaderPreset?
    var passes: [ShaderPassConfig] = []
    var selectedPassIndex: Int?
    var isLivePreview: Bool = true
    var isDirty: Bool = false

    // MARK: - Actions

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
    }

    func updateParameter(passIndex: Int, key: String, value: ShaderParameterValue) {
        guard passes.indices.contains(passIndex) else { return }
        passes[passIndex].parameters[key] = value
        isDirty = true
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
