import SwiftUI

// MARK: - Artisan Ruler Dial (精密刻度拨盘)
// 模仿高端相机的物理拨环，提供极高的视觉档次与精密调节感。
struct ArtisanRulerDial: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let unit: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // 数值指示器
            HStack(alignment: .firstTextBaseline) {
                Text(label)
                    .font(.system(size: 7, weight: .black))
                    .kerning(1.5)
                    .foregroundStyle(.white.opacity(0.2))
                Spacer()
                Text("\(Int(value))")
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.6))
                Text(unit)
                    .font(.system(size: 6.5, weight: .bold))
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
                                    .frame(width: 1, height: 3)
                            }
                        }
                        
                        // 粉色指针
                        Circle()
                            .fill(LiquidGlassColors.primaryPink)
                            .frame(width: 6, height: 6)
                            .overlay(Circle().stroke(Color.white.opacity(0.8), lineWidth: 1))
                            .artisanShadow(color: LiquidGlassColors.primaryPink.opacity(0.2), radius: 4)
                            .offset(x: pointerX - 3)
                    }
                }

                Slider(value: $value, in: range)
                    .accentColor(.clear)
                    .opacity(0.1)
            }
            .frame(height: 12)
        }
        .frame(width: 150)
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
            VStack(spacing: 6) { // 减小间距以适应高度
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .light))
                    .foregroundStyle(isSelected ? LiquidGlassColors.primaryPink : .white.opacity(0.15))
                    .frame(width: 28, height: 28) // 缩小图标
                    .background(Circle().fill(isSelected ? .white.opacity(0.04) : .clear))
                
                Text(label)
                    .font(.system(size: 8, weight: .black))
                    .kerning(1.5)
                    .foregroundStyle(isSelected ? LiquidGlassColors.primaryPink : .white.opacity(0.25))
            }
            .frame(width: 72)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Artisan Particle System
struct ParticleOverlay: View {
    var style: String = "circle.fill"
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
        // 限制最大粒子数，防止极端参数导致系统卡顿
        let maxDisplayParticles = 800
        let particleCount = min(Int(rate * (lifetime > 0 ? lifetime : 1)), maxDisplayParticles)
        
        // 预解析样式图片，杜绝在循环中重复创建对象
        let resolvedSymbol = style == "circle.fill" ? nil : context.resolve(Image(systemName: style))
        
        for i in 0..<particleCount {
            let seed = Double(i)
            let birthTime = seed / (rate > 0 ? rate : 1.0)
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
                
                // Velocity with Thrust and Angle
                let radAngle = (angle + (sin(cycleSeed * 32.1) * spread * 0.5)) * .pi / 180.0
                let vx = (sin(cycleSeed * 78.9) * turbulence * 20) + (cos(radAngle) * thrust * 10)
                let vy = (gravity * currentAge * 50) + (sin(radAngle) * thrust * 10)
                
                let currentX = startX + vx * currentAge
                let currentY = startY + vy * currentAge
                
                // Rotation
                let rotation = currentAge * spin * 5.0
                
                // Advanced Opacity Logic (Fade In / Fade Out)
                var opacity: Double = 0.6
                let inDuration = (fadeIn / 100.0)
                let outDuration = (fadeOut / 100.0)
                
                if progress < inDuration {
                    opacity *= (progress / (inDuration > 0 ? inDuration : 0.01))
                } else if progress > (1.0 - outDuration) {
                    opacity *= ((1.0 - progress) / (outDuration > 0 ? outDuration : 0.01))
                }
                
                let color = colorStart.opacity(opacity)
                let pSize = self.size * (1.0 - progress * 0.5)
                
                if let symbol = resolvedSymbol {
                    // 绘制预解析的图标 (极速)
                    var copy = context
                    copy.translateBy(x: currentX, y: currentY)
                    copy.rotate(by: .degrees(rotation))
                    copy.opacity = opacity
                    copy.addFilter(.colorMultiply(colorStart)) 
                    copy.draw(symbol, at: .zero)
                } else {
                    // 绘制原生圆形 (极速)
                    let rect = CGRect(x: currentX - pSize/2, y: currentY - pSize/2, width: pSize, height: pSize)
                    context.fill(Path(ellipseIn: rect), with: .color(color))
                }
            }
        }
    }
}
