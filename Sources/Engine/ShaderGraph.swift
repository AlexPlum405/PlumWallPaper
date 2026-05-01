// Sources/Engine/ShaderGraph.swift
import Foundation
import Metal

@MainActor
final class ShaderGraph {
    private(set) var passes: [any ShaderPassProtocol] = []
    private let device: MTLDevice
    private let library: MTLLibrary

    init(device: MTLDevice) throws {
        self.device = device
        guard let library = device.makeDefaultLibrary() else {
            throw ShaderError.pipelineCreationFailed
        }
        self.library = library
    }

    func addPass(_ pass: any ShaderPassProtocol) {
        passes.append(pass)
        if let compute = pass as? ComputeShaderPass {
            try? compute.buildPipeline(device: device, library: library)
        }
    }

    func removePass(id: UUID) {
        passes.removeAll { $0.id == id }
    }

    func reorderPass(from: Int, to: Int) {
        let pass = passes.remove(at: from)
        passes.insert(pass, at: to)
    }

    func updateParameter(passId: UUID, key: String, value: Float) {
        guard let passIndex = passes.firstIndex(where: { $0.id == passId }),
              let paramIndex = passes[passIndex].parameters.firstIndex(where: { $0.key == key }) else { return }
        passes[passIndex].parameters[paramIndex].value = value
    }

    func execute(input: MTLTexture, commandBuffer: MTLCommandBuffer) -> MTLTexture {
        var current = input
        for pass in passes where pass.enabled {
            current = pass.execute(input: current, commandBuffer: commandBuffer, device: device)
        }
        return current
    }
}
