import SwiftUI

struct AdjustGroup<Content: View>: View {
    let label: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(label.uppercased())
                .font(Theme.Fonts.ui(size: 11, weight: .bold))
                .tracking(2)
                .foregroundColor(.white.opacity(0.35))
            
            VStack(alignment: .leading, spacing: 24) {
                content()
            }
        }
    }
}

struct AdjustRow: View {
    let label: String
    @Binding var value: Double
    var range: ClosedRange<Double> = 0...200
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(label)
                    .font(Theme.Fonts.ui(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
                Text("\(Int(value))")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(Theme.accent)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // 背景轨道
                    Capsule()
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 3)
                    
                    // 激活轨道
                    Capsule()
                        .fill(Theme.accent)
                        .frame(width: geo.size.width * CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound)), height: 3)
                        .shadow(color: Theme.accent.opacity(0.3), radius: 4)
                    
                    // 拖拽滑块 (100% 原型还原: 白色球 + 红色边框 + 发光)
                    Circle()
                        .fill(Color.white)
                        .frame(width: 14, height: 14)
                        .overlay(
                            Circle()
                                .stroke(Theme.accent, lineWidth: 2)
                        )
                        .shadow(color: Theme.accent.opacity(0.6), radius: 10)
                        .offset(x: geo.size.width * CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound)) - 7)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { val in
                            let percent = min(max(0, val.location.x / geo.size.width), 1)
                            value = range.lowerBound + (range.upperBound - range.lowerBound) * Double(percent)
                        }
                )
            }
            .frame(height: 12)
        }
        .onHover { isHovered = $0 }
    }
}
