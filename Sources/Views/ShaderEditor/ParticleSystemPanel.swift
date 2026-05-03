import SwiftUI

// MARK: - Particle System Data Model
struct ParticleEmitterConfig: Identifiable, Equatable {
    let id: UUID
    var name: String
    var position: SIMD2<Float>           // 0-1 归一化坐标
    var rate: Float                      // 粒子/秒
    var lifetimeMin: Float               // 最小生命周期（秒）
    var lifetimeMax: Float               // 最大生命周期（秒）
    var velocity: SIMD2<Float>           // 初速度向量
    var velocityVariance: SIMD2<Float>   // 速度随机偏差
    var gravity: SIMD2<Float>            // 重力加速度
    var colorStart: Color                // 起始颜色
    var colorEnd: Color                  // 结束颜色
    var sizeStart: Float                 // 起始大小（像素）
    var sizeEnd: Float                   // 结束大小（像素）
    var texture: String?                 // 纹理名称
}

// MARK: - Particle System Panel (Pure Edition)
struct ParticleSystemPanel: View {
    @State internal var emitters: [ParticleEmitterConfig] = [
        ParticleEmitterConfig(id: UUID(), name: "主发射器", position: [0.5, 0.5], rate: 50, lifetimeMin: 1.0, lifetimeMax: 3.0, velocity: [0, -10], velocityVariance: [5, 5], gravity: [0, 9.8], colorStart: .white, colorEnd: .blue, sizeStart: 5, sizeEnd: 2, texture: nil)
    ]
    @State internal var selectedEmitterID: UUID?
    
    private var selectedEmitter: ParticleEmitterConfig? {
        emitters.first { $0.id == selectedEmitterID } ?? emitters.first
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // 左侧：发射器垂直导航（极简）
            emitterSidebar
            
            // 右侧：主编辑区
            if let emitter = selectedEmitter {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 48) {
                        // 1. 核心能量（核心动力学）
                        coreEnergySection(for: emitter)
                        
                        // 2. 空间布局（坐标系统）
                        spatialSection(for: emitter)
                        
                        // 3. 视觉演化
                        aestheticEvolutionSection(for: emitter)
                        
                        // 4. 操作底座
                        actionDock(for: emitter)
                    }
                    .padding(50)
                }
            } else {
                emptyState
            }
        }
        .background(VisualEffectView(material: .sidebar, blendingMode: .withinWindow).ignoresSafeArea())
    }
    
    // MARK: - Emitter Sidebar
    private var emitterSidebar: some View {
        VStack(spacing: 20) {
            ForEach(emitters) { emitter in
                Button(action: { selectEmitter(emitter.id) }) {
                    Circle()
                        .fill(selectedEmitterID == emitter.id ? LiquidGlassColors.primaryPink : Color.white.opacity(0.1))
                        .frame(width: 8, height: 8)
                        .overlay(
                            Circle().stroke(Color.white.opacity(0.2), lineWidth: 1)
                                .frame(width: 16, height: 16)
                                .opacity(selectedEmitterID == emitter.id ? 1 : 0)
                        )
                }
                .buttonStyle(.plain)
                .help(emitter.name)
            }
            
            Divider().frame(width: 20).opacity(0.2)
            
            Button(action: { addEmitter() }) {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .light))
                    .foregroundStyle(LiquidGlassColors.textSecondary)
            }
            .buttonStyle(.plain)
        }
        .frame(width: 60)
        .padding(.vertical, 40)
        .background(Color.black.opacity(0.1))
    }
    
    // MARK: - Sections
    
    private func coreEnergySection(for emitter: ParticleEmitterConfig) -> some View {
        VStack(alignment: .leading, spacing: 32) {
            ArtisanHeader(title: "CORE ENERGY", subtitle: "能量场输出频率")
            
            HStack(alignment: .bottom, spacing: 60) {
                // 发射速率拨盘感设计
                VStack(alignment: .leading, spacing: 12) {
                    Text("Emission Rate").font(.system(size: 11, weight: .black)).kerning(1.5).foregroundStyle(LiquidGlassColors.textQuaternary)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(Int(emitter.rate))").font(.system(size: 44, weight: .ultraLight, design: .serif))
                        Text("p/s").font(.system(size: 10, weight: .bold)).foregroundStyle(LiquidGlassColors.primaryPink)
                    }
                    Slider(value: Binding(get: { emitter.rate }, set: { setEmitterRate(emitter.id, $0) }), in: 1...300).tint(LiquidGlassColors.primaryPink)
                }
                .frame(maxWidth: .infinity)
                
                // 生命周期范围
                VStack(alignment: .leading, spacing: 12) {
                    Text("Lifetime Span").font(.system(size: 11, weight: .black)).kerning(1.5).foregroundStyle(LiquidGlassColors.textQuaternary)
                    HStack(spacing: 8) {
                        Text(String(format: "%.1fs", emitter.lifetimeMin)).font(.system(size: 16, weight: .light))
                        Rectangle().frame(width: 20, height: 1).opacity(0.2)
                        Text(String(format: "%.1fs", emitter.lifetimeMax)).font(.system(size: 16, weight: .bold))
                    }
                    Slider(value: Binding(get: { emitter.lifetimeMax }, set: { setEmitterLifeMax(emitter.id, $0) }), in: 0.1...10.0).tint(LiquidGlassColors.accentGold)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    private func spatialSection(for emitter: ParticleEmitterConfig) -> some View {
        VStack(alignment: .leading, spacing: 32) {
            ArtisanHeader(title: "SPATIAL DYNAMICS", subtitle: "空间场力与定位")
            
            HStack(spacing: 40) {
                // 坐标定位板 (Simplified Pad)
                VStack(alignment: .leading, spacing: 16) {
                    Text("Origin Position").font(.system(size: 10, weight: .black)).kerning(1).foregroundStyle(LiquidGlassColors.textQuaternary)
                    ZStack {
                        RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.03))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
                        
                        // 网格辅助线
                        Path { p in
                            p.move(to: CGPoint(x: 0, y: 75))
                            p.addLine(to: CGPoint(x: 150, y: 75))
                            p.move(to: CGPoint(x: 75, y: 0))
                            p.addLine(to: CGPoint(x: 75, y: 150))
                        }.stroke(Color.white.opacity(0.05), lineWidth: 1)
                        
                        Circle().fill(LiquidGlassColors.primaryPink)
                            .frame(width: 8, height: 8)
                            .offset(x: CGFloat(emitter.position.x - 0.5) * 150, y: CGFloat(emitter.position.y - 0.5) * 150)
                            .artisanShadow(color: LiquidGlassColors.primaryPink, radius: 10)
                    }
                    .frame(width: 150, height: 150)
                }
                
                // 速度与重力（合并为紧凑组）
                VStack(spacing: 24) {
                    ArtisanValueRow(title: "Velocity", valX: emitter.velocity.x, valY: emitter.velocity.y, color: LiquidGlassColors.tertiaryBlue)
                    ArtisanValueRow(title: "Variance", valX: emitter.velocityVariance.x, valY: emitter.velocityVariance.y, color: LiquidGlassColors.accentGold)
                    ArtisanValueRow(title: "Gravity", valX: emitter.gravity.x, valY: emitter.gravity.y, color: .white)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    private func aestheticEvolutionSection(for emitter: ParticleEmitterConfig) -> some View {
        VStack(alignment: .leading, spacing: 32) {
            ArtisanHeader(title: "AESTHETIC EVOLUTION", subtitle: "视觉形态与色彩演化")
            
            VStack(spacing: 24) {
                // 色彩渐变条
                HStack(spacing: 20) {
                    ColorPicker("", selection: Binding(get: { emitter.colorStart }, set: { setEmitterColorStart(emitter.id, $0) })).labelsHidden()
                    
                    LinearGradient(gradient: Gradient(colors: [emitter.colorStart, emitter.colorEnd]), startPoint: .leading, endPoint: .trailing)
                        .frame(height: 4)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 1))
                    
                    ColorPicker("", selection: Binding(get: { emitter.colorEnd }, set: { setEmitterColorEnd(emitter.id, $0) })).labelsHidden()
                }
                
                // 大小演化
                HStack(spacing: 40) {
                    ArtisanSliderTiny(title: "START SIZE", value: Binding(get: { emitter.sizeStart }, set: { setEmitterSizeStart(emitter.id, $0) }), range: 1...50)
                    ArtisanSliderTiny(title: "END SIZE", value: Binding(get: { emitter.sizeEnd }, set: { setEmitterSizeEnd(emitter.id, $0) }), range: 0...50)
                }
                
                // 粒子材质选择，避免把 SF Symbol 当作粒子贴图
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(ParticleMaterial.allCases) { material in
                        let isActive = emitter.texture == material.rawValue
                        Button {
                            setEmitterTexture(emitter.id, material.rawValue)
                        } label: {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(material.title)
                                    .font(.system(size: 11, weight: .bold))
                                Text(material.detail)
                                    .font(.system(size: 9, weight: .medium))
                                    .lineLimit(1)
                            }
                            .foregroundStyle(isActive ? LiquidGlassColors.primaryPink : .white.opacity(0.42))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 10)
                            .frame(height: 46)
                            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(isActive ? Color.white.opacity(0.08) : Color.white.opacity(0.025)))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
    
    private func actionDock(for emitter: ParticleEmitterConfig) -> some View {
        HStack {
            Button(action: { resetEmitter(emitter.id) }) {
                Text("RESET")
                    .font(.system(size: 10, weight: .black)).kerning(2)
                    .foregroundStyle(LiquidGlassColors.textSecondary)
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            Button(action: { applyToDesktop() }) {
                Text("APPLY TO GALLERY")
                    .font(.system(size: 11, weight: .black)).kerning(2)
                    .padding(.horizontal, 30).frame(height: 44)
                    .background(LiquidGlassColors.primaryPink)
                    .clipShape(Capsule())
                    .artisanShadow(color: LiquidGlassColors.primaryPink.opacity(0.4), radius: 20)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 20)
    }
    
    private var emptyState: some View {
        VStack {
            Image(systemName: "sparkle")
                .font(.system(size: 40, weight: .ultraLight))
                .foregroundStyle(LiquidGlassColors.textQuaternary)
            Text("NO EMITTER SELECTED")
                .font(.system(size: 12, weight: .black)).kerning(4)
                .foregroundStyle(LiquidGlassColors.textQuaternary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Sub-Components

struct ArtisanHeader: View {
    let title: String
    let subtitle: String
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.system(size: 12, weight: .black)).kerning(3).foregroundStyle(LiquidGlassColors.textSecondary)
            Text(subtitle).font(.system(size: 10, weight: .medium)).italic().foregroundStyle(LiquidGlassColors.textQuaternary)
            Rectangle().frame(width: 40, height: 2).foregroundStyle(LiquidGlassColors.primaryPink).padding(.top, 4)
        }
    }
}

struct ArtisanValueRow: View {
    let title: String
    let valX: Float
    let valY: Float
    let color: Color
    var body: some View {
        HStack {
            Text(title).font(.system(size: 10, weight: .bold)).foregroundStyle(LiquidGlassColors.textQuaternary)
            Spacer()
            HStack(spacing: 12) {
                Text(String(format: "X: %.1f", valX)).font(.system(size: 11, weight: .medium, design: .monospaced))
                Text(String(format: "Y: %.1f", valY)).font(.system(size: 11, weight: .medium, design: .monospaced))
            }
            .foregroundStyle(color)
        }
        .padding(.bottom, 8)
        .overlay(Divider().opacity(0.1), alignment: .bottom)
    }
}

struct ArtisanSliderTiny: View {
    let title: String
    @Binding var value: Float
    let range: ClosedRange<Float>
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title).font(.system(size: 9, weight: .black)).kerning(1).foregroundStyle(LiquidGlassColors.textQuaternary)
                Spacer()
                Text("\(Int(value))").font(.system(size: 10, weight: .bold, design: .monospaced))
            }
            Slider(value: $value, in: range).tint(LiquidGlassColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}
