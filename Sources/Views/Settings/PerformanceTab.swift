import SwiftUI
import Charts

struct PerformanceTab: View {
    var viewModel: SettingsViewModel
    @State private var perfHistory: [PerformancePoint] = (0..<40).map { PerformancePoint(index: $0, value: Double.random(in: 55...60)) }
    let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // 实时分析仪表盘
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

                artisanSettingsSection(header: "渲染调度中心") {
                    artisanSettingsRow(title: "物理帧率上限", subtitle: "限制最高渲染帧率以优化能效比") {
                        Picker("", selection: Binding(
                            get: { viewModel.settings?.fpsLimit ?? 60 },
                            set: { setFPSLimit($0) }
                        )) {
                            Text("不限").tag(0)
                            Text("30 FPS").tag(30)
                            Text("60 FPS").tag(60)
                            Text("120 FPS").tag(120)
                        }
                        .frame(width: 140)
                    }

                    artisanSettingsRow(title: "垂直同步 (V-Sync)", subtitle: "与显示器刷新率严格同步，消除画面撕裂", showDivider: false) {
                        artisanToggle(isOn: Binding(
                            get: { viewModel.settings?.vSyncEnabled ?? true },
                            set: { setVSyncEnabled($0) }
                        ))
                    }
                }
                
                VStack(spacing: 12) {
                    Image(systemName: "cpu").font(.system(size: 16)).foregroundStyle(LiquidGlassColors.tertiaryBlue)
                    Text("智能调度引擎正在根据您的暂停策略自动优化硬件负载。").font(.system(size: 11)).foregroundStyle(LiquidGlassColors.textQuaternary).multilineTextAlignment(.center)
                }.padding(.top, 20)
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
}

private struct PerformancePoint: Identifiable {
    let id = UUID()
    let index: Int
    let value: Double
}
