import SwiftUI

// MARK: - Artisan Darkroom Lab (Scheme C: Artisan Gallery)
// 这里是 Plum 的后期实验室，每一行着色器都在雕琢光影的艺术。

struct ShaderEditorView: View {
    @State private var selectedPassIndex = 0
    
    // 渲染管线通道 (维持结构兼容)
    let passes = ["基础滤镜 (Core)", "粒子系统 (Kinetic)", "后期处理 (Final)", "色彩校正 (Color)"]

    var body: some View {
        HStack(spacing: 0) {
            // 1. 左侧：暗房通道索引
            artisanPassSidebar
            
            // 2. 右侧：实验室调节大厅
                // 核心内容切换
                ZStack {
                    if selectedPassIndex == 1 {
                        ParticleSystemPanel()
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 56) {
                                // 标题区 (Artisan Typography)
                                HStack(alignment: .bottom) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("RENDERING PASS")
                                            .font(.system(size: 10, weight: .black)).kerning(2.5).foregroundStyle(LiquidGlassColors.textQuaternary)
                                        Text(passes[selectedPassIndex])
                                            .artisanTitleStyle(size: 32)
                                    }
                                    Spacer()
                                    artisanHeaderToggle(label: "全时渲染引擎", isOn: .constant(true))
                                }
                                
                                // 实验调节区 (精密卡片组)
                                VStack(spacing: 32) {
                                    artisanParameterCard(title: "光学基础中心", icon: "camera.filters") {
                                        artisanParamSlider(label: "曝光强度控制", value: .constant(0.5), unit: "EV")
                                        artisanParamSlider(label: "反差系数调节", value: .constant(0.8), unit: "CO")
                                        artisanParamSlider(label: "色彩纯度重映射", value: .constant(1.2), unit: "SA")
                                    }
                                    
                                    artisanParameterCard(title: "物理交互仿真", icon: "atom") {
                                        artisanParamToggle(label: "开启实时重力感应碰撞", isOn: .constant(true))
                                        artisanParamToggle(label: "启用高动态 HDR 映射", isOn: .constant(false))
                                        artisanParamSlider(label: "流体湍流强度", value: .constant(0.3), unit: "PX")
                                    }
                                }
                                
                                Spacer().frame(height: 100)
                            }
                            .padding(64)
                        }
                    }
                }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(LiquidGlassColors.deepBackground)
        }
    }
    
    // MARK: - A. 视觉子组件
    
    private var artisanPassSidebar: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("暗房实验室")
                .artisanTitleStyle(size: 20)
                .padding(.leading, 12)
                .padding(.bottom, 24)
            
            ForEach(0..<passes.count, id: \.self) { index in
                LiquidGlassNavButton(
                    title: passes[index],
                    icon: "f.circle.fill",
                    isSelected: selectedPassIndex == index,
                    color: LiquidGlassColors.primaryPink
                ) {
                    withAnimation(.gallerySpring) { selectedPassIndex = index }
                }
            }
            
            Spacer()
            
            // 新增通道按钮 (Artisan Dash)
            Button(action: {}) {
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                    Text("新增渲染层级")
                }
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(LiquidGlassColors.primaryPink)
                .padding(.horizontal, 16).padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(LiquidGlassColors.primaryPink.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.bottom, 32)
        }
        .padding(.top, 40)
        .padding(.horizontal, 16)
        .frame(width: 280)
        .background(LiquidGlassBackgroundView(material: .sidebar))
        .overlay(Rectangle().fill(LiquidGlassColors.glassBorder).frame(width: 0.5), alignment: .trailing)
    }
    
    private func artisanParameterCard<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 28) {
            HStack(spacing: 12) {
                Image(systemName: icon).font(.system(size: 14, weight: .bold)).foregroundStyle(LiquidGlassColors.primaryPink)
                Text(title).font(.system(size: 14, weight: .black)).kerning(1.5).foregroundStyle(LiquidGlassColors.textPrimary)
            }
            
            VStack(spacing: 24) { content() }
        }
        .padding(32)
        .galleryCardStyle(radius: 24, padding: 0)
    }
    
    private func artisanParamSlider(label: String, value: Binding<Double>, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(label).font(.system(size: 13, weight: .bold)).foregroundStyle(LiquidGlassColors.textSecondary)
                Spacer()
                Text(String(format: "%.2f", value.wrappedValue))
                    .font(.system(size: 11, weight: .bold, design: .monospaced)).foregroundStyle(LiquidGlassColors.primaryPink)
                Text(unit).font(.system(size: 8, weight: .black)).foregroundStyle(LiquidGlassColors.textQuaternary)
            }
            Slider(value: value).tint(LiquidGlassColors.primaryPink)
        }
    }
    
    private func artisanParamToggle(label: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(label).font(.system(size: 13, weight: .bold)).foregroundStyle(LiquidGlassColors.textSecondary)
            Spacer()
            artisanToggleWidget(isOn: isOn)
        }
    }
    
    private func artisanHeaderToggle(label: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            Text(label).font(.system(size: 11, weight: .black)).kerning(1).foregroundStyle(LiquidGlassColors.textQuaternary)
            artisanToggleWidget(isOn: isOn)
        }
    }
    
    private func artisanToggleWidget(isOn: Binding<Bool>) -> some View {
        Button { withAnimation(.gallerySpring) { isOn.wrappedValue.toggle() } } label: {
            ZStack {
                Capsule().fill(isOn.wrappedValue ? LiquidGlassColors.primaryPink : Color.white.opacity(0.1)).frame(width: 36, height: 20)
                Circle().fill(Color.white).frame(width: 16, height: 16).shadow(color: .black.opacity(0.2), radius: 2).offset(x: isOn.wrappedValue ? 8 : -8)
            }
        }.buttonStyle(.plain)
    }
}
