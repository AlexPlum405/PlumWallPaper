import SwiftUI
import SwiftData

// MARK: - Artisan Darkroom Lab (Scheme C: Artisan Gallery)
struct ShaderEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = ShaderEditorViewModel()
    @State private var selectedPassIndex = 0

    private var particlePanelIndex: Int { viewModel.passes.count }

    var body: some View {
        HStack(spacing: 0) {
            artisanPassSidebar

            ZStack {
                if selectedPassIndex == particlePanelIndex {
                    ParticleSystemPanel()
                } else if viewModel.passes.indices.contains(selectedPassIndex) {
                    passEditor(passIndex: selectedPassIndex)
                } else {
                    artisanEmptyEditor
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(LiquidGlassColors.deepBackground)
        }
        .onAppear { viewModel.configure(modelContext: modelContext) }
    }

    private var artisanPassSidebar: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("暗房实验室")
                .artisanTitleStyle(size: 20)
                .padding(.leading, 12)
                .padding(.bottom, 24)

            ForEach(viewModel.passes.indices, id: \.self) { index in
                LiquidGlassNavButton(
                    title: viewModel.passes[index].name,
                    icon: viewModel.passes[index].enabled ? "f.circle.fill" : "f.circle",
                    isSelected: selectedPassIndex == index,
                    color: LiquidGlassColors.primaryPink
                ) {
                    withAnimation(.gallerySpring) { selectedPassIndex = index }
                }
            }

            LiquidGlassNavButton(
                title: "粒子系统",
                icon: "circle.hexagongrid.fill",
                isSelected: selectedPassIndex == particlePanelIndex,
                color: LiquidGlassColors.primaryPink
            ) {
                withAnimation(.gallerySpring) { selectedPassIndex = particlePanelIndex }
            }

            Spacer()

            Button {
                viewModel.addPass(type: .filter, name: "自定义曝光 \(viewModel.passes.count + 1)")
                viewModel.updateParameter(passIndex: viewModel.passes.count - 1, key: "exposure", value: .float(0))
                selectedPassIndex = max(0, viewModel.passes.count - 1)
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                    Text("新增渲染层级")
                }
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(LiquidGlassColors.primaryPink)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
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

    private func passEditor(passIndex: Int) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 56) {
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("RENDERING PASS")
                            .font(.system(size: 10, weight: .black))
                            .kerning(2.5)
                            .foregroundStyle(LiquidGlassColors.textQuaternary)
                        Text(viewModel.passes[passIndex].name)
                            .artisanTitleStyle(size: 32)
                    }
                    Spacer()
                    artisanHeaderToggle(label: "实时预览", isOn: Binding(
                        get: { viewModel.isLivePreview },
                        set: {
                            viewModel.isLivePreview = $0
                            if $0 { viewModel.applyToEngine() }
                        }
                    ))
                }

                VStack(spacing: 32) {
                    artisanParameterCard(title: "通道开关", icon: "power.circle") {
                        artisanParamToggle(label: "启用此渲染通道", isOn: Binding(
                            get: { viewModel.passes[passIndex].enabled },
                            set: { _ in viewModel.togglePass(at: passIndex) }
                        ))
                    }

                    artisanParameterCard(title: "光学参数", icon: "camera.filters") {
                        parameterControls(for: passIndex)
                    }
                }

                HStack(spacing: 16) {
                    Button {
                        viewModel.revert()
                    } label: {
                        Text("还原")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(LiquidGlassColors.textSecondary)
                            .frame(width: 120, height: 44)
                            .galleryCardStyle(radius: 14, padding: 0)
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.preset == nil)

                    Button {
                        viewModel.applyToEngine()
                    } label: {
                        Text("应用到桌面")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 140, height: 44)
                            .background(Capsule().fill(LiquidGlassColors.primaryViolet))
                    }
                    .buttonStyle(.plain)

                    Button {
                        viewModel.save()
                    } label: {
                        Text(viewModel.isDirty ? "保存预设" : "已保存")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 140, height: 44)
                            .background(Capsule().fill(LiquidGlassColors.primaryPink))
                    }
                    .buttonStyle(.plain)
                }

                Spacer().frame(height: 80)
            }
            .padding(64)
        }
    }

    @ViewBuilder
    private func parameterControls(for passIndex: Int) -> some View {
        let pass = viewModel.passes[passIndex]
        switch pass.name {
        case "曝光调整":
            artisanParamSlider(label: "曝光强度控制", value: floatBinding(passIndex: passIndex, key: "exposure", defaultValue: 0), range: -1...1, unit: "EV")
        case "对比度":
            artisanParamSlider(label: "反差系数调节", value: floatBinding(passIndex: passIndex, key: "contrast", defaultValue: 1), range: 0...2, unit: "CO")
        case "饱和度":
            artisanParamSlider(label: "色彩纯度重映射", value: floatBinding(passIndex: passIndex, key: "saturation", defaultValue: 1), range: 0...2, unit: "SA")
        case "色调旋转":
            artisanParamSlider(label: "色调旋转角度", value: floatBinding(passIndex: passIndex, key: "hue", defaultValue: 0), range: -180...180, unit: "DEG")
        case "灰度", "反转", "暗角":
            artisanParamSlider(label: "\(pass.name)强度", value: floatBinding(passIndex: passIndex, key: "intensity", defaultValue: 0), range: 0...1, unit: "FX")
        default:
            artisanParamSlider(label: "曝光强度控制", value: floatBinding(passIndex: passIndex, key: "exposure", defaultValue: 0), range: -1...1, unit: "EV")
        }
    }

    private var artisanEmptyEditor: some View {
        VStack(spacing: 18) {
            Image(systemName: "camera.filters")
                .font(.system(size: 46, weight: .ultraLight))
                .foregroundStyle(LiquidGlassColors.textQuaternary)
            Text("选择一个渲染通道开始调校")
                .font(.custom("Georgia", size: 16).italic())
                .foregroundStyle(LiquidGlassColors.textQuaternary)
        }
    }

    private func artisanParameterCard<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 28) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(LiquidGlassColors.primaryPink)
                Text(title)
                    .font(.system(size: 14, weight: .black))
                    .kerning(1.5)
                    .foregroundStyle(LiquidGlassColors.textPrimary)
            }

            VStack(spacing: 24) { content() }
        }
        .padding(32)
        .galleryCardStyle(radius: 24, padding: 0)
    }

    private func artisanParamSlider(label: String, value: Binding<Double>, range: ClosedRange<Double>, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(label)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(LiquidGlassColors.textSecondary)
                Spacer()
                Text(String(format: "%.2f", value.wrappedValue))
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(LiquidGlassColors.primaryPink)
                Text(unit)
                    .font(.system(size: 8, weight: .black))
                    .foregroundStyle(LiquidGlassColors.textQuaternary)
            }
            Slider(value: value, in: range)
                .tint(LiquidGlassColors.primaryPink)
        }
    }

    private func artisanParamToggle(label: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(LiquidGlassColors.textSecondary)
            Spacer()
            artisanToggleWidget(isOn: isOn)
        }
    }

    private func artisanHeaderToggle(label: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.system(size: 11, weight: .black))
                .kerning(1)
                .foregroundStyle(LiquidGlassColors.textQuaternary)
            artisanToggleWidget(isOn: isOn)
        }
    }

    private func artisanToggleWidget(isOn: Binding<Bool>) -> some View {
        Button { withAnimation(.gallerySpring) { isOn.wrappedValue.toggle() } } label: {
            ZStack {
                Capsule()
                    .fill(isOn.wrappedValue ? LiquidGlassColors.primaryPink : Color.white.opacity(0.1))
                    .frame(width: 36, height: 20)
                Circle()
                    .fill(Color.white)
                    .frame(width: 16, height: 16)
                    .shadow(color: .black.opacity(0.2), radius: 2)
                    .offset(x: isOn.wrappedValue ? 8 : -8)
            }
        }
        .buttonStyle(.plain)
    }

    private func floatBinding(passIndex: Int, key: String, defaultValue: Float) -> Binding<Double> {
        Binding(
            get: { Double(floatValue(passIndex: passIndex, key: key, defaultValue: defaultValue)) },
            set: { viewModel.updateParameter(passIndex: passIndex, key: key, value: .float(Float($0))) }
        )
    }

    private func floatValue(passIndex: Int, key: String, defaultValue: Float) -> Float {
        guard viewModel.passes.indices.contains(passIndex),
              let value = viewModel.passes[passIndex].parameters[key] else {
            return defaultValue
        }

        switch value {
        case .float(let number):
            return number
        case .int(let number):
            return Float(number)
        default:
            return defaultValue
        }
    }
}
