// Sources/Engine/ParticleEmitter.swift
import Foundation
import simd

struct ParticleEmitterEngineConfig {
    var position: SIMD2<Float>
    var emissionRate: Float
    var lifetime: Float
    var velocityMin: SIMD2<Float>
    var velocityMax: SIMD2<Float>
    var sizeStart: Float
    var sizeEnd: Float
    var colorStart: SIMD4<Float>
    var colorEnd: SIMD4<Float>
}

struct Particle {
    var position: SIMD2<Float>
    var velocity: SIMD2<Float>
    var lifetime: Float
    var age: Float
    var size: Float
    var color: SIMD4<Float>
}

final class ParticleEmitter {
    let id: UUID
    var config: ParticleEmitterEngineConfig
    var enabled: Bool
    private var accumulator: Float = 0

    init(id: UUID = UUID(), config: ParticleEmitterEngineConfig) {
        self.id = id
        self.config = config
        self.enabled = true
    }

    func emit(deltaTime: Float) -> [Particle] {
        guard enabled else { return [] }
        accumulator += deltaTime * config.emissionRate
        let count = Int(accumulator)
        accumulator -= Float(count)

        return (0..<count).map { _ in
            Particle(
                position: config.position,
                velocity: SIMD2<Float>(
                    Float.random(in: config.velocityMin.x...config.velocityMax.x),
                    Float.random(in: config.velocityMin.y...config.velocityMax.y)
                ),
                lifetime: config.lifetime,
                age: 0,
                size: config.sizeStart,
                color: config.colorStart
            )
        }
    }
}
