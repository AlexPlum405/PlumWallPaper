import SwiftUI
import Charts

struct PerformanceTab: View {
    var viewModel: SettingsViewModel
    @State private var perfHistory: [PerformancePoint] = (0..<40).map { PerformancePoint(index: $0, value: Double.random(in: 55...60)) }
    let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // MARK: - [动力实时分析]
                VStack(alignment: .leading, spacing: 20) {
                    LiquidGlassSectionHeader(title: "动力实时分析", icon: "waveform.path.ecg", color: LiquidGlassColors.tertiaryBlue)
                    Chart(perfHistory) { point in
                        LineMark(x: .value("Time", point.index), y: .value("FPS", point.value))
                            .foregroundStyle(LiquidGlassColors.tertiaryBlue)
                            .interpolationMethod(.catmullRom)
                        AreaMark(x: .value("Time", point.index), y: .value("FPS", point.value))
                            .foregroundStyle(LinearGradient(colors: [LiquidGlassColors.tertiaryBlue.opacity(0.15), .clear], startPoint: .top, endPoint: .bottom))
                            .interpolationMethod(.catmullRom)
                    }
                    .chartYScale(domain: 0...120).chartXAxis(.hidden)
                    .frame(height: 120).padding(24).galleryCardStyle(radius: 20, padding: 0)
                }
                .onReceive(timer) { _ in updatePerfHistory() }

                // MARK: - [渲染调度中心]
                artisanSettingsSection(header: "渲染调度中心 (RENDERING HUB)") {
                    artisanSettingsRow(title: "物理帧率上限", subtitle: "限制最高渲染帧率以优化能效比") {
                        Picker("", selection: Binding(
                            get: { viewModel.settings?.fpsLimit ?? 60 },
                            set: { setFPSLimit($0) }
                        )) {
                            Text("不限").tag(0)
                            Text("30").tag(30)
                            Text("60").tag(60)
                            Text("120").tag(120)
                        }
                        .frame(width: 140)
                    }

                    artisanSettingsRow(title: "自动降帧策略", subtitle: "进入省电或高压场景时优先降低渲染成本", showDivider: false) {
                        Image(systemName: "bolt.badge.clock.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(LiquidGlassColors.warningOrange)
                    }
                }

                // MARK: - [全局暂停策略]
                VStack(alignment: .leading, spacing: 20) {
                    LiquidGlassSectionHeader(title: "全局暂停策略", icon: "power", color: LiquidGlassColors.warningOrange)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        pauseStrategyCard(icon: "battery.100.bolt", title: "电池供电", 
                                        isOn: Binding(get: { viewModel.settings?.pauseOnBattery ?? true }, 
                                                    set: { setPauseOnBattery($0) }))

                        pauseStrategyCard(icon: "arrow.up.left.and.arrow.down.right", title: "全屏应用", 
                                        isOn: Binding(get: { viewModel.settings?.pauseOnFullscreen ?? true }, 
                                                    set: { setPauseOnFullscreen($0) }))

                        pauseStrategyCardWithThreshold(
                            icon: "battery.25", 
                            title: "低电量", 
                            isOn: Binding(get: { viewModel.settings?.pauseOnLowBattery ?? true }, 
                                        set: { setPauseOnLowBattery($0) }),
                            threshold: Binding(get: { viewModel.settings?.lowBatteryThreshold ?? 20 }, 
                                             set: { setLowBatteryThreshold($0) })
                        )

                        pauseStrategyCard(icon: "rectangle.on.rectangle", title: "屏幕共享", 
                                        isOn: Binding(get: { viewModel.settings?.pauseOnScreenSharing ?? false }, 
                                                    set: { setPauseOnScreenSharing($0) }))

                        pauseStrategyCard(icon: "cpu", title: "高负载", 
                                        isOn: Binding(get: { viewModel.settings?.pauseOnHighLoad ?? true }, 
                                                    set: { setPauseOnHighLoad($0) }))
                    }
                }
            }
            .padding(.top, 32)
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }
    
    private func updatePerfHistory() {
        perfHistory.removeFirst()
        perfHistory.append(PerformancePoint(index: (perfHistory.last?.index ?? 0) + 1, value: Double.random(in: 58...60)))
    }

    private func pauseStrategyCard(icon: String, title: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(isOn.wrappedValue ? LiquidGlassColors.warningOrange : LiquidGlassColors.textQuaternary)
                .frame(width: 32)

            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(LiquidGlassColors.textPrimary)

            Spacer()

            artisanToggle(isOn: isOn)
        }
        .padding(20)
        .galleryCardStyle(radius: 16, padding: 0)
    }

    private func pauseStrategyCardWithThreshold(icon: String, title: String, isOn: Binding<Bool>, threshold: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(isOn.wrappedValue ? LiquidGlassColors.warningOrange : LiquidGlassColors.textQuaternary)
                    .frame(width: 32)

                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(LiquidGlassColors.textPrimary)

                Spacer()

                artisanToggle(isOn: isOn)
            }

            if isOn.wrappedValue {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("触发阈值").font(.system(size: 11, weight: .medium)).foregroundStyle(LiquidGlassColors.textSecondary)
                        Spacer()
                        Text("\(threshold.wrappedValue)%").font(.system(size: 11, weight: .bold, design: .monospaced)).foregroundStyle(LiquidGlassColors.warningOrange)
                    }
                    Slider(value: Binding(get: { Double(threshold.wrappedValue) }, set: { threshold.wrappedValue = Int($0) }), in: 5...50, step: 5)
                        .tint(LiquidGlassColors.warningOrange)
                }
                .padding(.top, 4)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(20)
        .galleryCardStyle(radius: 16, padding: 0)
    }
}

private struct PerformancePoint: Identifiable {
    let id = UUID()
    let index: Int
    let value: Double
}
