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
    var colorStart: Color
    var colorEnd: Color

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let now = timeline.date.timeIntervalSinceReferenceDate
                let particleCount = Int(rate * lifetime)
                
                for i in 0..<particleCount {
                    let seed = Double(i)
                    let birthTime = seed / rate
                    let age = now - birthTime
                    let cycle = floor(max(0, age) / lifetime)
                    let currentAge = max(0, age) - cycle * lifetime
                    
                    if currentAge >= 0 && currentAge <= lifetime {
                        let progress = currentAge / lifetime
                        
                        // Determinitic pseudo-random based on seed + cycle
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
                        
                        // Basic interpolation without NSColor complex calls for performance
                        let opacity = (1.0 - progress) * 0.6
                        let color = colorStart.opacity(opacity)
                        
                        let pSize = self.size * (1.0 - progress * 0.5)
                        
                        var innerContext = context
                        innerContext.translateBy(x: currentX, y: currentY)
                        innerContext.rotate(by: .degrees(rotation))
                        
                        if style == "circle.fill" {
                            let rect = CGRect(x: -pSize/2, y: -pSize/2, width: pSize, height: pSize)
                            innerContext.fill(Path(ellipseIn: rect), with: .color(color))
                        } else {
                            // Draw system icon as text
                            innerContext.draw(
                                Text(Image(systemName: style))
                                    .font(.system(size: pSize))
                                    .foregroundStyle(color),
                                at: .zero
                            )
                        }
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }
}
