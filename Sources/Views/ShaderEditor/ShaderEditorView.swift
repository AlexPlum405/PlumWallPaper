import SwiftUI

struct ShaderEditorView: View {
    @State private var selectedPassIndex = 0
    
    // Mock 数据
    let passes = ["基础滤镜", "粒子系统", "后期处理", "色彩校正"]

    var body: some View {
        HStack(spacing: 0) {
            // 左侧：通道列表
            VStack(alignment: .leading, spacing: 20) {
                Text("着色器通道")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.bottom, 10)
                
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(0..<passes.count, id: \.self) { index in
                            PassRow(title: passes[index], isSelected: selectedPassIndex == index) {
                                selectedPassIndex = index
                            }
                        }
                        
                        Button(action: {}) {
                            Label("添加通道", systemImage: "plus.circle.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(LiquidGlassColors.primaryPink)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(RoundedRectangle(cornerRadius: 12).stroke(LiquidGlassColors.primaryPink.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4])))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(width: 260)
            .padding(30)
            .background(Color.black.opacity(0.2))

            // 右侧：参数编辑区
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(passes[selectedPassIndex])
                                .font(.system(size: 32, weight: .bold))
                                .foregroundStyle(.white)
                            Text("正在编辑当前渲染管线的参数")
                                .font(.system(size: 14))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                        Spacer()
                        Toggle("启用", isOn: .constant(true))
                            .toggleStyle(.switch)
                    }
                    .padding(.bottom, 20)

                    // 参数卡片
                    VStack(spacing: 20) {
                        ParameterCard(title: "基础属性") {
                            ParameterSlider(label: "亮度 (Brightness)", value: .constant(0.5))
                            ParameterSlider(label: "对比度 (Contrast)", value: .constant(0.8))
                            ParameterSlider(label: "饱和度 (Saturation)", value: .constant(1.2))
                        }
                        
                        ParameterCard(title: "高级控制") {
                            ParameterToggle(label: "开启 HDR", isOn: .constant(true))
                            ParameterToggle(label: "自适应模糊", isOn: .constant(false))
                            ParameterSlider(label: "模糊强度 (Blur)", value: .constant(0.3))
                        }
                    }
                }
                .padding(40)
            }
        }
    }
}

// 子组件：通道行
struct PassRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "f.circle.fill")
                    .foregroundStyle(isSelected ? .white : LiquidGlassColors.primaryPink)
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.8))
                Spacer()
                if isSelected {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10))
                        .foregroundStyle(.white)
                }
            }
            .padding()
            .background(isSelected ? LiquidGlassColors.primaryPink : Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.white.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// 子组件：参数卡片
struct ParameterCard<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(LiquidGlassColors.primaryPink)
            
            VStack(spacing: 16) {
                content
            }
        }
        .padding(24)
        .background(Color.black.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
    }
}

struct ParameterSlider: View {
    let label: String
    @Binding var value: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label).font(.system(size: 13)).foregroundStyle(.white)
                Spacer()
                Text(String(format: "%.2f", value)).font(.system(size: 12, design: .monospaced)).foregroundStyle(.white.opacity(0.6))
            }
            Slider(value: $value)
                .tint(LiquidGlassColors.primaryPink)
        }
    }
}

struct ParameterToggle: View {
    let label: String
    @Binding var isOn: Bool
    
    var body: some View {
        Toggle(label, isOn: $isOn)
            .font(.system(size: 13))
            .foregroundStyle(.white)
    }
}
