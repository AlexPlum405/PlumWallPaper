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
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(label)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(LiquidGlassColors.textSecondary)
                Spacer()
                Text("\(Int(value))")
                    .font(.system(size: 20, weight: .light, design: .serif))
                    .foregroundStyle(.white)
                Text(unit)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(LiquidGlassColors.primaryPink)
            }
            .padding(.horizontal, 2)
            
            // 刻度尺区域
            ZStack {
                // 背景长轨
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 1)
                
                // 刻度线
                HStack(spacing: 6) {
                    ForEach(0..<21) { i in
                        Rectangle()
                            .fill(i % 5 == 0 ? Color.white.opacity(0.5) : Color.white.opacity(0.2))
                            .frame(width: 1, height: i % 5 == 0 ? 10 : 5)
                    }
                }
                
                // 指针
                Rectangle()
                    .fill(LiquidGlassColors.primaryPink)
                    .frame(width: 2, height: 16)
                    .artisanShadow(color: LiquidGlassColors.primaryPink.opacity(0.5), radius: 4)
                
                // 交互层
                Slider(value: $value, in: range)
                    .accentColor(.clear)
                    .opacity(0.01)
            }
            .frame(height: 20)
        }
        .frame(width: 130)
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
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(isSelected ? .black : .white)
                    .frame(width: 40, height: 40)
                    .background(isSelected ? LiquidGlassColors.primaryPink : Color.white.opacity(0.05))
                    .clipShape(Circle())
                
                Text(label)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(isSelected ? LiquidGlassColors.primaryPink : .white.opacity(0.4))
            }
        }
        .buttonStyle(.plain)
    }
}
