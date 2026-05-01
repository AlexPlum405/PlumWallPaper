// Sources/Engine/ParticleSystem.swift
import Foundation
import Metal

final class ParticleSystem: ShaderPassProtocol {
    let id: UUID
    let name: String = "粒子系统"
    let type: ShaderPassType = .particle
    var enabled: Bool = false
    var parameters: [ShaderParameter]

    var emitters: [ParticleEmitter] = []
    private var particleBuffer: MTLBuffer?
    private var updatePipeline: MTLComputePipelineState?
    private var renderPipeline: MTLComputePipelineState?
    private let maxParticles = 1_000_000
    private var aliveCount: Int = 0
    private var particles: [Particle] = []

    init(id: UUID = UUID(), device: MTLDevice) {
        self.id = id
        self.parameters = [
            ShaderParameter(id: UUID(), key: "gravityX", name: "重力 X", value: 0, min: -5, max: 5, defaultValue: 0),
            ShaderParameter(id: UUID(), key: "gravityY", name: "重力 Y", value: -1, min: -5, max: 5, defaultValue: -1),
        ]

        let bufferSize = MemoryLayout<Particle>.stride * maxParticles
        particleBuffer = device.makeBuffer(length: bufferSize, options: .storageModeShared)

        if let library = device.makeDefaultLibrary() {
            updatePipeline = try? device.makeComputePipelineState(
                function: library.makeFunction(name: "updateParticles")!)
            renderPipeline = try? device.makeComputePipelineState(
                function: library.makeFunction(name: "renderParticles")!)
        }
    }

    func update(deltaTime: Float) {
        for emitter in emitters {
            let newParticles = emitter.emit(deltaTime: deltaTime)
            particles.append(contentsOf: newParticles)
        }

        particles.removeAll { $0.age >= $0.lifetime }

        if particles.count > maxParticles {
            particles = Array(particles.suffix(maxParticles))
        }

        aliveCount = particles.count
    }

    func execute(input: MTLTexture, commandBuffer: MTLCommandBuffer, device: MTLDevice) -> MTLTexture {
        guard enabled, aliveCount > 0, let buffer = particleBuffer,
              let updatePipe = updatePipeline else { return input }

        let ptr = buffer.contents().bindMemory(to: Particle.self, capacity: maxParticles)
        for i in 0..<aliveCount {
            ptr[i] = particles[i]
        }

        let gravityX = parameters.first(where: { $0.key == "gravityX" })?.value ?? 0
        let gravityY = parameters.first(where: { $0.key == "gravityY" })?.value ?? -1
        var params: [Float] = [1.0/60.0, gravityX, gravityY]

        guard let encoder = commandBuffer.makeComputeCommandEncoder() else { return input }
        encoder.setComputePipelineState(updatePipe)
        encoder.setBuffer(buffer, offset: 0, index: 0)
        encoder.setBytes(&params, length: MemoryLayout<Float>.stride * 3, index: 1)
        let threadGroupSize = MTLSize(width: min(256, aliveCount), height: 1, depth: 1)
        let threadGroups = MTLSize(width: (aliveCount + 255) / 256, height: 1, depth: 1)
        encoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupSize)
        encoder.endEncoding()

        return input
    }
}
