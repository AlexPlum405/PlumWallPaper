import SwiftUI

// MARK: - Particle System Logic Extension (Kinetic)
extension ParticleSystemPanel {
    
    // MARK: - Emitter Management
    
    func selectEmitter(_ id: UUID) {
        withAnimation(.gallerySpring) {
            selectedEmitterID = id
        }
    }
    
    func addEmitter() {
        let newEmitter = ParticleEmitterConfig(
            id: UUID(),
            name: "新发射器 \(emitters.count + 1)",
            position: [0.5, 0.5],
            rate: 20,
            lifetimeMin: 1.0,
            lifetimeMax: 2.0,
            velocity: [0, -5],
            velocityVariance: [2, 2],
            gravity: [0, 0],
            colorStart: .white,
            colorEnd: .white.opacity(0.5),
            sizeStart: 2,
            sizeEnd: 2,
            texture: nil
        )
        withAnimation(.gallerySpring) {
            emitters.append(newEmitter)
            selectedEmitterID = newEmitter.id
        }
    }
    
    func deleteEmitter(_ id: UUID) {
        withAnimation(.gallerySpring) {
            emitters.removeAll { $0.id == id }
            if selectedEmitterID == id {
                selectedEmitterID = emitters.first?.id
            }
        }
    }
    
    // MARK: - Parameter Setters (Binding Handlers)
    
    private func updateEmitter(_ id: UUID, transform: (inout ParticleEmitterConfig) -> Void) {
        if let index = emitters.firstIndex(where: { $0.id == id }) {
            transform(&emitters[index])
        }
    }
    
    func setEmitterPosX(_ id: UUID, _ value: Float) {
        updateEmitter(id) { $0.position.x = value }
    }
    
    func setEmitterPosY(_ id: UUID, _ value: Float) {
        updateEmitter(id) { $0.position.y = value }
    }
    
    func setEmitterRate(_ id: UUID, _ value: Float) {
        updateEmitter(id) { $0.rate = value }
    }
    
    func setEmitterLifeMin(_ id: UUID, _ value: Float) {
        updateEmitter(id) { $0.lifetimeMin = value }
    }
    
    func setEmitterLifeMax(_ id: UUID, _ value: Float) {
        updateEmitter(id) { $0.lifetimeMax = value }
    }
    
    func setEmitterVelX(_ id: UUID, _ value: Float) {
        updateEmitter(id) { $0.velocity.x = value }
    }
    
    func setEmitterVelY(_ id: UUID, _ value: Float) {
        updateEmitter(id) { $0.velocity.y = value }
    }
    
    func setEmitterVarX(_ id: UUID, _ value: Float) {
        updateEmitter(id) { $0.velocityVariance.x = value }
    }
    
    func setEmitterVarY(_ id: UUID, _ value: Float) {
        updateEmitter(id) { $0.velocityVariance.y = value }
    }
    
    func setEmitterGravX(_ id: UUID, _ value: Float) {
        updateEmitter(id) { $0.gravity.x = value }
    }
    
    func setEmitterGravY(_ id: UUID, _ value: Float) {
        updateEmitter(id) { $0.gravity.y = value }
    }
    
    func setEmitterColorStart(_ id: UUID, _ value: Color) {
        updateEmitter(id) { $0.colorStart = value }
    }
    
    func setEmitterColorEnd(_ id: UUID, _ value: Color) {
        updateEmitter(id) { $0.colorEnd = value }
    }
    
    func setEmitterSizeStart(_ id: UUID, _ value: Float) {
        updateEmitter(id) { $0.sizeStart = value }
    }
    
    func setEmitterSizeEnd(_ id: UUID, _ value: Float) {
        updateEmitter(id) { $0.sizeEnd = value }
    }
    
    func setEmitterTexture(_ id: UUID, _ value: String) {
        updateEmitter(id) { $0.texture = value }
    }
    
    // MARK: - Presets & Actions
    
    func applyPreset(_ name: String, to id: UUID) {
        updateEmitter(id) { emitter in
            switch name {
            case "雪花":
                emitter.rate = 100
                emitter.velocity = [0, 5]
                emitter.velocityVariance = [10, 2]
                emitter.gravity = [0, 1]
                emitter.colorStart = .white
                emitter.colorEnd = .white.opacity(0.3)
                emitter.sizeStart = 4
                emitter.sizeEnd = 4
                emitter.texture = ParticleMaterial.snow.rawValue
            case "火花":
                emitter.rate = 200
                emitter.velocity = [0, -50]
                emitter.velocityVariance = [20, 20]
                emitter.gravity = [0, 20]
                emitter.colorStart = .orange
                emitter.colorEnd = .red
                emitter.sizeStart = 2
                emitter.sizeEnd = 0
                emitter.texture = ParticleMaterial.ember.rawValue
            default: break
            }
        }
    }
    
    func resetEmitter(_ id: UUID) {
        updateEmitter(id) { emitter in
            emitter.rate = 50
            emitter.position = [0.5, 0.5]
            emitter.velocity = [0, -10]
            emitter.gravity = [0, 9.8]
            emitter.colorStart = .white
            emitter.colorEnd = .blue
        }
    }
    
    func applyToDesktop() {
        guard let emitter = emitters.first(where: { $0.id == selectedEmitterID }) ?? emitters.first else { return }
        let material = ParticleMaterial(style: emitter.texture)
        let velocityLength = hypot(Double(emitter.velocity.x), Double(emitter.velocity.y))
        let varianceLength = hypot(Double(emitter.velocityVariance.x), Double(emitter.velocityVariance.y))
        let angle = atan2(Double(emitter.velocity.y), Double(emitter.velocity.x)) * 180.0 / .pi

        var effects = WallpaperRenderEffects.identity
        effects.name = "粒子系统编辑器"
        effects.particleStyle = material.rawValue
        effects.particleRate = Double(emitter.rate)
        effects.particleLifetime = Double(max(emitter.lifetimeMin, emitter.lifetimeMax))
        effects.particleSize = Double(max(emitter.sizeStart, emitter.sizeEnd))
        effects.particleGravity = Double(emitter.gravity.y)
        effects.weatherWind = Double(emitter.gravity.x)
        effects.particleTurbulence = max(1, varianceLength)
        effects.particleThrust = velocityLength / 10.0
        effects.particleAngle = angle
        effects.particleSpread = 90
        effects.particleFadeIn = 8
        effects.particleFadeOut = 38

        if material == .rain {
            effects.weatherRain = min(100, Double(emitter.rate) * 0.35)
        }
        if material == .snow {
            effects.weatherSnow = min(100, Double(emitter.rate) * 0.28)
        }

        RenderPipeline.shared.updateEnvironmentEffects(effects)
    }
}
