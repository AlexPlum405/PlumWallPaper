import SwiftUI
import AppKit
import Charts

// MARK: - 高保真复刻 WaifuX 设置窗口 (像素级同步版)

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = SettingsViewModel()
    @State private var selectedTab: SettingsTab = .general
    @State private var toast: ToastConfig?

    private let sidebarWidth: CGFloat = 180

    var body: some View {
        HStack(spacing: 0) {
            // === 左侧导航栏 ===
            sidebar

            // 分割线 (WaifuX 风格极细线)
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 1)

            // === 右侧内容区 ===
            VStack(spacing: 0) {
                // 标题行
                HStack {
                    Text(selectedTab.title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.9))

                    Spacer()

                    // 关闭按钮
                    Button {
                        // 关闭窗口
                        NSApp.keyWindow?.performClose(nil)
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.45))
                            .frame(width: 24, height: 24)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 16)

                Divider()
                    .background(Color.white.opacity(0.06))

                // 内容区域 (使用 WaifuX 同款容器)
                MacSettingsForm {
                    contentView(for: selectedTab)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(width: 800, height: 550)
        .background(Color(hex: "1C1C1E")) // 强制 WaifuX 背景色
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .toast($toast)
        .onAppear {
            viewModel.configure(modelContext: modelContext)
        }
    }

    // MARK: 左侧导航栏
    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(SettingsTab.allCases) { tab in
                SidebarItem(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                        }
                    }
                )
            }
            Spacer()
        }
        .padding(.top, 16)
        .padding(.horizontal, 10)
        .frame(width: sidebarWidth)
        .background(
            ZStack {
                Color(hex: "1A1A1A").opacity(0.85) // WaifuX 同款侧边栏背景
                VisualEffectView(material: .sidebar)
                    .allowsHitTesting(false)
            }
        )
    }

    @ViewBuilder
    private func contentView(for tab: SettingsTab) -> some View {
        switch tab {
        case .general: GeneralSettingsTab(viewModel: viewModel)
        case .appearance: AppearanceSettingsTab(viewModel: viewModel)
        case .performance: PerformanceSettingsTab(viewModel: viewModel)
        case .display: DisplaySettingsTab(viewModel: viewModel)
        case .appRules: AppRulesTabV2(viewModel: viewModel, toast: $toast)
        case .library: LibrarySettingsTab(viewModel: viewModel)
        case .about: AboutSettingsTab()
        }
    }
}

// MARK: - 设置标签枚举
private enum SettingsTab: String, CaseIterable, Identifiable {
    case general, appearance, performance, display, appRules, library, about
    var id: Self { self }
    var title: String {
        switch self {
        case .general: return "通用"
        case .appearance: return "外观"
        case .performance: return "性能"
        case .display: return "显示器"
        case .appRules: return "应用规则"
        case .library: return "存储"
        case .about: return "关于"
        }
    }
    var icon: String {
        switch self {
        case .general: return "gearshape"
        case .appearance: return "paintpalette"
        case .performance: return "cpu"
        case .display: return "desktopcomputer"
        case .appRules: return "shield.fill"
        case .library: return "folder"
        case .about: return "info.circle"
        }
    }
}

// MARK: - 侧边栏项
private struct SidebarItem: View {
    let tab: SettingsTab
    let isSelected: Bool
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: tab.icon)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                    .frame(width: 20)
                Text(tab.title)
                    .font(.system(size: 13, weight: isSelected ? .medium : .regular))
                Spacer()
            }
            .foregroundStyle(isSelected ? Color.white : Color.white.opacity(0.5))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(isSelected ? Color.white.opacity(0.1) : (isHovered ? Color.white.opacity(0.05) : Color.clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(isSelected ? Color.white.opacity(0.12) : Color.clear, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}

// MARK: - WaifuX 风格设置表单组件

struct MacSettingsForm<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        ScrollView {
            VStack(spacing: 24) { content }
            .padding(.horizontal, 28)
            .padding(.vertical, 20)
        }
        .scrollIndicators(.hidden)
    }
}

struct MacSettingsSection<Content: View>: View {
    let header: String?
    let content: Content
    init(header: String? = nil, @ViewBuilder content: () -> Content) {
        self.header = header
        self.content = content()
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let header {
                Text(header)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color.white.opacity(0.4))
                    .padding(.leading, 2)
            }
            VStack(spacing: 0) { content }
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.05)))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.08), lineWidth: 0.5))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

struct MacSettingsRow<Trailing: View>: View {
    let title: String
    let subtitle: String?
    let trailing: Trailing
    let showDivider: Bool
    init(title: String, subtitle: String? = nil, showDivider: Bool = true, @ViewBuilder trailing: () -> Trailing) {
        self.title = title; self.subtitle = subtitle; self.showDivider = showDivider; self.trailing = trailing()
    }
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.system(size: 13, weight: .medium)).foregroundStyle(.white.opacity(0.9))
                    if let subtitle { Text(subtitle).font(.system(size: 11)).foregroundStyle(.white.opacity(0.4)) }
                }
                Spacer()
                trailing
            }
            .padding(.horizontal, 16).padding(.vertical, 12)
            if showDivider { Divider().background(Color.white.opacity(0.06)).padding(.leading, 16) }
        }
    }
}

struct MacToggle: View {
    @Binding var isOn: Bool
    var body: some View {
        Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) { isOn.toggle() }
        } label: {
            ZStack {
                Capsule()
                    .fill(isOn ? Color(hex: "30D158") : Color.white.opacity(0.2))
                    .frame(width: 38, height: 20)
                Circle()
                    .fill(Color.white)
                    .frame(width: 16, height: 16)
                    .shadow(color: .black.opacity(0.2), radius: 1, y: 0.5)
                    .offset(x: isOn ? 9 : -9)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 子模块实现

private struct GeneralSettingsTab: View {
    var viewModel: SettingsViewModel
    var body: some View {
        VStack(spacing: 24) {
            MacSettingsSection(header: "语言与地区") {
                MacSettingsRow(title: "显示语言", subtitle: "设置应用程序界面的显示语言") {
                    HStack(spacing: 4) {
                        Text("中文").font(.system(size: 13)).foregroundStyle(.white.opacity(0.6))
                        Image(systemName: "chevron.up.chevron.down").font(.system(size: 10)).foregroundStyle(.white.opacity(0.4))
                    }
                }
            }
            MacSettingsSection(header: "外观设置") {
                MacSettingsRow(title: "颗粒材质", subtitle: "胶片颗粒效果，让界面更有质感") {
                    MacToggle(isOn: .constant(true))
                }
                MacSettingsRow(title: "自动下载原图", showDivider: false) {
                    MacToggle(isOn: .constant(false))
                }
            }
        }
    }
}

private struct AppearanceSettingsTab: View {
    var viewModel: SettingsViewModel
    var body: some View {
        MacSettingsSection(header: "主题") {
            MacSettingsRow(title: "外观模式", showDivider: false) {
                Picker("", selection: Binding(get: { viewModel.settings?.themeMode ?? .auto }, set: { viewModel.setTheme($0) })) {
                    Text("自动").tag(ThemeMode.auto)
                    Text("浅色").tag(ThemeMode.light)
                    Text("深色").tag(ThemeMode.dark)
                }
                .pickerStyle(.segmented).frame(width: 150)
            }
        }
    }
}

private struct PerformanceSettingsTab: View {
    var viewModel: SettingsViewModel
    @State private var perfHistory: [PerformancePoint] = (0..<40).map { PerformancePoint(index: $0, value: Double.random(in: 55...60)) }
    let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 32) {
            // 1. 实时分析看板 (极致专业感)
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    LiquidGlassSectionHeader(title: "实时性能分析", icon: "waveform.path.ecg", color: LiquidGlassColors.accentCyan)
                    Spacer()
                    Text("渲染压力: 低").font(.system(size: 11, weight: .bold)).foregroundStyle(LiquidGlassColors.onlineGreen)
                }
                
                Chart(perfHistory) { point in
                    LineMark(x: .value("Time", point.index), y: .value("FPS", point.value))
                        .foregroundStyle(LiquidGlassColors.accentCyan)
                        .interpolationMethod(.catmullRom)
                    
                    AreaMark(x: .value("Time", point.index), y: .value("FPS", point.value))
                        .foregroundStyle(LinearGradient(colors: [LiquidGlassColors.accentCyan.opacity(0.2), .clear], startPoint: .top, endPoint: .bottom))
                        .interpolationMethod(.catmullRom)
                }
                .chartYScale(domain: 0...120)
                .chartXAxis(.hidden)
                .frame(height: 120)
                .padding(20)
                .background(Color.black.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .onReceive(timer) { _ in
                perfHistory.removeFirst()
                perfHistory.append(PerformancePoint(index: (perfHistory.last?.index ?? 0) + 1, value: Double.random(in: 58...60)))
            }
            
            // 2. 帧率与同步
            MacSettingsSection(header: "渲染调度") {
                MacSettingsRow(title: "FPS 刷新上限", subtitle: "更高的帧率意味着更流畅的动画，但会消耗更多电力") {
                    HStack(spacing: 12) {
                        Slider(value: Binding(get: { Double(viewModel.settings?.fpsLimit ?? 60) }, set: { viewModel.settings?.fpsLimit = Int($0); viewModel.save() }), in: 15...144, step: 1)
                            .frame(width: 120).tint(LiquidGlassColors.primaryPink)
                        Text("\(viewModel.settings?.fpsLimit ?? 60)").font(.system(size: 12, weight: .bold, design: .monospaced)).frame(width: 30)
                    }
                }
                MacSettingsRow(title: "开启垂直同步 (VSync)", subtitle: "消除画面撕裂，建议开启", showDivider: false) {
                    MacToggle(isOn: Binding(get: { viewModel.settings?.vSyncEnabled ?? true }, set: { viewModel.settings?.vSyncEnabled = $0; viewModel.save() }))
                }
            }
            
            // 3. 智能暂停 (重头戏)
            VStack(alignment: .leading, spacing: 16) {
                LiquidGlassSectionHeader(title: "全自动智能暂停策略", icon: "bolt.shield.fill", color: Color.orange)
                
                VStack(spacing: 0) {
                    MacSettingsRow(title: "使用电池时暂停") {
                        MacToggle(isOn: Binding(get: { viewModel.settings?.pauseOnBattery ?? false }, set: { viewModel.settings?.pauseOnBattery = $0; viewModel.save() }))
                    }
                    
                    MacSettingsRow(title: "低电量模式自动暂停") {
                        HStack(spacing: 12) {
                            let thresholdBinding = Binding<Double>(
                                get: { Double(viewModel.settings?.lowBatteryThreshold ?? 20) },
                                set: { viewModel.settings?.lowBatteryThreshold = Int($0); viewModel.save() }
                            )
                            Slider(value: thresholdBinding, in: 5...50, step: 5)
                                .frame(width: 100).tint(.orange)
                            let thresholdText: String = "\(viewModel.settings?.lowBatteryThreshold ?? 20)%"
                            Text(thresholdText).font(.system(size: 11, weight: .bold)).frame(width: 35)
                            let lowBatteryBinding = Binding<Bool>(
                                get: { viewModel.settings?.pauseOnLowBattery ?? true },
                                set: { viewModel.settings?.pauseOnLowBattery = $0; viewModel.save() }
                            )
                            MacToggle(isOn: lowBatteryBinding)
                        }
                    }
                    
                    MacSettingsRow(title: "高负载自动保护", subtitle: "当 CPU/GPU 负载超过阈值时暂停以保证系统流畅") {
                        HStack(spacing: 12) {
                            Text("阈值: 80%").font(.system(size: 11, weight: .bold)).foregroundStyle(.secondary)
                            MacToggle(isOn: .constant(true))
                        }
                    }
                    
                    MacSettingsRow(title: "屏幕共享/录屏时暂停", showDivider: false) {
                        MacToggle(isOn: Binding(get: { viewModel.settings?.pauseOnScreenSharing ?? true }, set: { viewModel.settings?.pauseOnScreenSharing = $0; viewModel.save() }))
                    }
                }
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05)))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 1))
            }
        }
    }
}

private struct DisplaySettingsTab: View {
    var viewModel: SettingsViewModel
    var body: some View {
        MacSettingsSection(header: "显示器配置") {
            MacSettingsRow(title: "拓扑模式", showDivider: false) {
                Picker("", selection: Binding(get: { viewModel.settings?.displayTopology ?? .independent }, set: { viewModel.setDisplayTopology($0) })) {
                    Text("独立").tag(DisplayTopology.independent)
                    Text("镜像").tag(DisplayTopology.mirror)
                    Text("全景").tag(DisplayTopology.panorama)
                }
                .pickerStyle(.menu).frame(width: 100)
            }
        }
    }
}

private struct LibrarySettingsTab: View {
    var viewModel: SettingsViewModel
    var body: some View {
        MacSettingsSection(header: "存储管理") {
            MacSettingsRow(title: "资源存储路径", subtitle: viewModel.settings?.libraryPath ?? "/Users/Shared/Plum") {
                Button("更改") { }.buttonStyle(.bordered).controlSize(.small)
            }
        }
    }
}

private struct AboutSettingsTab: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(nsImage: NSApp.applicationIconImage).resizable().frame(width: 64, height: 64)
            VStack(spacing: 4) {
                Text("PlumWallPaper").font(.system(size: 18, weight: .bold))
                Text("Version 1.0.0").font(.system(size: 12)).foregroundStyle(.white.opacity(0.4))
            }
            MacSettingsSection(header: "项目信息") {
                HStack {
                    Text("开发者").font(.system(size: 13, weight: .medium)).foregroundStyle(.white.opacity(0.9))
                    Spacer()
                    Text("Plum Studio").font(.system(size: 13)).foregroundStyle(.white.opacity(0.45))
                }
                .padding(.horizontal, 16).padding(.vertical, 12)
            }
        }
    }
}

private struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView(); v.material = material; v.blendingMode = .withinWindow; v.state = .active; return v
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) { nsView.material = material }
}
