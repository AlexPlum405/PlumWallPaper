import SwiftUI

// MARK: - Artisan Ruler Dial (精密刻度拨盘)
// 模仿高端相机的物理拨环，提供极高的视觉档次与精密调节感。
struct ArtisanRulerDial: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let unit: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 数值指示器
            HStack(alignment: .firstTextBaseline) {
                Text(label)
                    .font(.system(size: 10, weight: .black))
                    .kerning(1.0)
                    .foregroundStyle(.white.opacity(0.2))
                Spacer()
                Text("\(Int(value))")
                    .font(.system(size: 16, weight: .regular, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.6))
                Text(unit)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(LiquidGlassColors.primaryPink.opacity(0.4))
            }
            
            // 刻度尺区域
            ZStack {
                // 背景发丝轨
                Rectangle()
                    .fill(Color.white.opacity(0.04))
                    .frame(height: 1)

                // 交互层与指针
                GeometryReader { geo in
                    let percentage = CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))
                    let pointerX = min(max(0, percentage * geo.size.width), geo.size.width)
                    
                    ZStack(alignment: .leading) {
                        // 虚像刻度
                        HStack(spacing: geo.size.width / 10) {
                            ForEach(0..<11) { i in
                                Rectangle()
                                    .fill(Color.white.opacity(0.05))
                                    .frame(width: 1, height: 5)
                            }
                        }
                        
                        // 粉色指针
                        Circle()
                            .fill(LiquidGlassColors.primaryPink)
                            .frame(width: 8, height: 8)
                            .overlay(Circle().stroke(Color.white.opacity(0.8), lineWidth: 1))
                            .artisanShadow(color: LiquidGlassColors.primaryPink.opacity(0.2), radius: 4)
                            .offset(x: pointerX - 4)
                    }
                }

                Slider(value: $value, in: range)
                    .accentColor(.clear)
                    .opacity(0.1)
            }
            .frame(height: 18)
        }
        .frame(width: 180)
    }
}

// MARK: - Artisan Horizon Tab (地平线切换点)
struct ArtisanHorizonTab: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .light))
                    .foregroundStyle(isSelected ? LiquidGlassColors.primaryPink : .white.opacity(0.15))
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(isSelected ? .white.opacity(0.04) : .clear))
                
                Text(label)
                    .font(.system(size: 11, weight: .black))
                    .kerning(0.9)
                    .foregroundStyle(isSelected ? LiquidGlassColors.primaryPink : .white.opacity(0.25))
            }
            .frame(width: 84)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Artisan Particle System
struct ParticleOverlay: View {
    var style: String = ParticleMaterial.dust.rawValue
    var rate: Double
    var lifetime: Double
    var size: Double
    var gravity: Double
    var turbulence: Double
    var spin: Double = 0
    var thrust: Double = 0
    var angle: Double = 0
    var spread: Double = 360
    var fadeIn: Double = 10  // % of lifetime
    var fadeOut: Double = 30 // % of lifetime
    var wind: Double = 0     // 全局风力场
    var isRainMode: Bool = false // 是否开启雨丝模式
    var colorStart: Color
    var colorEnd: Color

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                drawParticles(into: &context, size: size, at: timeline.date)
            }
        }
        .allowsHitTesting(false)
    }

    private func drawParticles(into context: inout GraphicsContext, size: CGSize, at date: Date) {
        let now = date.timeIntervalSinceReferenceDate
        let material = ParticleMaterial(style: style)
        // 限制最大粒子数
        let maxDisplayParticles = 800
        let materialRate = rate * material.previewDensityMultiplier
        let particleCount = min(Int(materialRate * (lifetime > 0 ? lifetime : 1)), maxDisplayParticles)
        
        for i in 0..<particleCount {
            let seed = Double(i)
            let birthTime = seed / (materialRate > 0 ? materialRate : 1.0)
            let age = now - birthTime
            let life = (lifetime > 0 ? lifetime : 1.0)
            let cycle = floor(max(0, age) / life)
            let currentAge = max(0, age) - cycle * life
            
            if currentAge >= 0 && currentAge <= life {
                let progress = currentAge / life
                
                // Deterministic pseudo-random based on seed + cycle
                let cycleSeed = seed + cycle * 1000
                let startX = (sin(cycleSeed * 12.3) * 0.5 + 0.5) * size.width
                let startY = (cos(cycleSeed * 45.6) * 0.5 + 0.5) * size.height
                
                // Velocity with Wind, Gravity, Thrust and Angle
                let radAngle = (angle + (sin(cycleSeed * 32.1) * spread * 0.5)) * .pi / 180.0

                // 风力叠加在水平速度上
                let vx = (sin(cycleSeed * 78.9) * turbulence * 20) + (cos(radAngle) * thrust * 10) + (wind * 10)
                let vy = (gravity * currentAge * 50) + (sin(radAngle) * thrust * 10)
                
                let currentX = startX + vx * currentAge
                let currentY = startY + vy * currentAge
                
                // Advanced Opacity Logic
                var opacity: Double = 0.6
                let inDuration = (fadeIn / 100.0)
                let outDuration = (fadeOut / 100.0)
                
                if progress < inDuration {
                    opacity *= (progress / (inDuration > 0 ? inDuration : 0.01))
                } else if progress > (1.0 - outDuration) {
                    opacity *= ((1.0 - progress) / (outDuration > 0 ? outDuration : 0.01))
                }
                
                let color = colorStart.opacity(opacity)
                let pSize = max(1, self.size * material.previewSizeMultiplier * (1.0 - progress * 0.5))
                let rotation = currentAge * spin * 5.0 + sin(cycleSeed * 4.7) * 24
                
                drawParticle(
                    material: isRainMode ? .rain : material,
                    into: &context,
                    point: CGPoint(x: currentX, y: currentY),
                    velocity: CGVector(dx: vx, dy: vy),
                    size: pSize,
                    rotation: rotation,
                    opacity: opacity,
                    color: color
                )
            }
        }
    }

    private func drawParticle(
        material: ParticleMaterial,
        into context: inout GraphicsContext,
        point: CGPoint,
        velocity: CGVector,
        size: Double,
        rotation: Double,
        opacity: Double,
        color: Color
    ) {
        let pSize = CGFloat(size)
        let rect = CGRect(x: point.x - pSize / 2, y: point.y - pSize / 2, width: pSize, height: pSize)

        switch material {
        case .dust:
            context.fill(Path(ellipseIn: rect), with: .color(color.opacity(0.55)))
        case .glow:
            var glow = context
            glow.addFilter(.blur(radius: max(1, pSize * 0.42)))
            glow.fill(Path(ellipseIn: rect.insetBy(dx: -pSize * 0.55, dy: -pSize * 0.55)), with: .color(color.opacity(0.38)))
            context.fill(Path(ellipseIn: rect.insetBy(dx: pSize * 0.32, dy: pSize * 0.32)), with: .color(Color.white.opacity(opacity * 0.66)))
        case .bokeh:
            var soft = context
            soft.addFilter(.blur(radius: max(2, pSize * 0.18)))
            soft.fill(Path(ellipseIn: rect), with: .color(color.opacity(0.18)))
            context.stroke(Path(ellipseIn: rect.insetBy(dx: pSize * 0.18, dy: pSize * 0.18)), with: .color(Color.white.opacity(opacity * 0.12)), lineWidth: max(0.5, pSize * 0.035))
        case .petal:
            var copy = context
            copy.translateBy(x: point.x, y: point.y)
            copy.rotate(by: .degrees(rotation))
            copy.fill(Self.petalPath(width: pSize * 1.85, height: pSize * 0.72), with: .color(color.opacity(0.72)))
            copy.stroke(Self.petalPath(width: pSize * 1.85, height: pSize * 0.72), with: .color(Color.white.opacity(opacity * 0.08)), lineWidth: 0.6)
        case .shard:
            var copy = context
            copy.translateBy(x: point.x, y: point.y)
            copy.rotate(by: .degrees(rotation))
            var path = Path()
            path.move(to: CGPoint(x: -pSize * 0.72, y: 0))
            path.addLine(to: CGPoint(x: pSize * 0.72, y: 0))
            copy.stroke(path, with: .color(color.opacity(0.74)), lineWidth: max(0.8, pSize * 0.18))
        case .ember:
            var glow = context
            glow.addFilter(.blur(radius: max(1, pSize * 0.55)))
            glow.fill(Path(ellipseIn: rect.insetBy(dx: -pSize * 0.45, dy: -pSize * 0.2)), with: .color(color.opacity(0.45)))
            var copy = context
            copy.translateBy(x: point.x, y: point.y)
            copy.rotate(by: .degrees(rotation))
            copy.fill(Path(ellipseIn: CGRect(x: -pSize * 0.55, y: -pSize * 0.24, width: pSize * 1.1, height: pSize * 0.48)), with: .color(color.opacity(0.82)))
        case .snow:
            var soft = context
            soft.addFilter(.blur(radius: max(0.8, pSize * 0.16)))
            soft.fill(Path(ellipseIn: rect), with: .color(Color.white.opacity(opacity * 0.66)))
        case .rain:
            var path = Path()
            let stretchX = max(-18, min(18, velocity.dx * 0.08))
            let stretchY = max(18, min(80, abs(velocity.dy) * 0.12))
            path.move(to: point)
            path.addLine(to: CGPoint(x: point.x - stretchX, y: point.y - stretchY))
            context.stroke(path, with: .color(color.opacity(0.55)), lineWidth: max(0.6, pSize * 0.14))
        case .mist:
            var mist = context
            mist.addFilter(.blur(radius: max(5, pSize * 0.42)))
            mist.fill(Path(ellipseIn: rect.insetBy(dx: -pSize * 0.45, dy: -pSize * 0.18)), with: .color(color.opacity(0.14)))
        case .firefly:
            var glow = context
            glow.addFilter(.blur(radius: max(2, pSize * 0.72)))
            glow.fill(Path(ellipseIn: rect.insetBy(dx: -pSize * 0.9, dy: -pSize * 0.9)), with: .color(color.opacity(0.36)))
            context.fill(Path(ellipseIn: rect.insetBy(dx: pSize * 0.34, dy: pSize * 0.34)), with: .color(Color.white.opacity(opacity * 0.78)))
        }
    }

    private static func petalPath(width: CGFloat, height: CGFloat) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: -width * 0.5, y: 0))
        path.addCurve(
            to: CGPoint(x: width * 0.5, y: 0),
            control1: CGPoint(x: -width * 0.24, y: -height),
            control2: CGPoint(x: width * 0.34, y: -height * 0.88)
        )
        path.addCurve(
            to: CGPoint(x: -width * 0.5, y: 0),
            control1: CGPoint(x: width * 0.28, y: height * 0.96),
            control2: CGPoint(x: -width * 0.28, y: height * 0.76)
        )
        return path
    }
}
