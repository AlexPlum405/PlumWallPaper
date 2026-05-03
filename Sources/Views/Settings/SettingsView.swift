import SwiftUI
import AppKit
import Charts

// MARK: - Artisan Parameter Studio (Scheme C: Artisan Gallery)
// 这里是 Plum 的精密心脏，每一个参数都以艺术化的方式呈现。

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = SettingsViewModel()
    @State private var selectedTab: SettingsTab = .general
    @State private var toast: ToastConfig?

    private let sidebarWidth: CGFloat = 200 

    var body: some View {
        HStack(spacing: 0) {
            // === 左侧策展导航 ===
            artisanSidebar

            // === 右侧工作室内容 ===
            VStack(spacing: 0) {
                // 画廊风格 Header
                HStack {
                    Text(selectedTab.title)
                        .artisanTitleStyle(size: 24, kerning: 1.5)
                        .foregroundStyle(LiquidGlassColors.textPrimary)

                    Spacer()

                    Button { NSApp.keyWindow?.performClose(nil) } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .light))
                            .foregroundStyle(LiquidGlassColors.textQuaternary)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color.white.opacity(0.05)))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 40)
                .padding(.top, 32)
                .padding(.bottom, 24)

                // 核心内容容器
                ZStack {
                    contentView(for: selectedTab)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(LiquidGlassColors.deepBackground)
        }
        .frame(width: 960, height: 680) // 略微增加尺寸以容纳更多控件
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 32, style: .continuous).stroke(LiquidGlassColors.glassBorder, lineWidth: 0.5))
        .toast($toast)
        .onAppear { viewModel.configure(modelContext: modelContext) }
    }

    // MARK: - 视觉组件
    
    private var artisanSidebar: some View {
        VStack(alignment: .leading, spacing: 6) {
            // 品牌标识
            HStack(spacing: 12) {
                Image(nsImage: NSApp.applicationIconImage ?? NSImage()).resizable().frame(width: 32, height: 32)
                Text("Studio")
                    .font(.custom("Georgia", size: 18).bold().italic())
                    .foregroundStyle(LiquidGlassColors.primaryPink)
            }
            .padding(.leading, 12)
            .padding(.bottom, 20)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(SettingsTab.allCases) { tab in
                        LiquidGlassNavButton(
                            title: tab.title,
                            icon: tab.icon,
                            isSelected: selectedTab == tab,
                            color: LiquidGlassColors.primaryPink
                        ) {
                            withAnimation(.gallerySpring) { selectedTab = tab }
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
            
            Spacer()
        }
        .padding(.top, 32)
        .padding(.horizontal, 16)
        .frame(width: sidebarWidth)
        .background(LiquidGlassBackgroundView(material: .sidebar))
        .overlay(Rectangle().fill(LiquidGlassColors.glassBorder).frame(width: 0.5), alignment: .trailing)
    }

    @ViewBuilder
    private func contentView(for tab: SettingsTab) -> some View {
        switch tab {
        case .general: GeneralSettingsTab(viewModel: viewModel)
        case .playback: PlaybackTab(viewModel: viewModel)
        case .performance: PerformanceTab(viewModel: viewModel)
        case .display: DisplayTab(viewModel: viewModel)
        case .advanced: AdvancedSettingsTab(viewModel: viewModel)
        case .about: AboutSettingsTab()
        }
    }
}

// MARK: - 设置标签枚举 (重构精简版)
private enum SettingsTab: String, CaseIterable, Identifiable {
    case general, playback, display, performance, advanced, about
    var id: Self { self }
    var title: String {
        switch self {
        case .general: return "通用"
        case .playback: return "播放与音频"
        case .display: return "显示与多屏"
        case .performance: return "性能"
        case .advanced: return "高级"
        case .about: return "关于"
        }
    }
    var icon: String {
        switch self {
        case .general: return "command"
        case .playback: return "play.circle.fill"
        case .display: return "display.2"
        case .performance: return "gauge.medium"
        case .advanced: return "slider.horizontal.3"
        case .about: return "info.circle.fill"
        }
    }
}

// MARK: - 画廊设置容器函数 (供所有 Tab 使用)

@ViewBuilder
func artisanSettingsSection<Content: View>(header: String? = nil, @ViewBuilder content: () -> Content) -> some View {
    VStack(alignment: .leading, spacing: 16) {
        if let header {
            Text(header).font(.system(size: 10, weight: .black)).kerning(2.5).foregroundStyle(LiquidGlassColors.textQuaternary)
                .padding(.leading, 4)
        }
        VStack(spacing: 0) { content() }
        .galleryCardStyle(radius: 20, padding: 0)
    }
}

@ViewBuilder
func artisanSettingsRow<Trailing: View>(title: String, subtitle: String? = nil, showDivider: Bool = true, @ViewBuilder trailing: () -> Trailing) -> some View {
    VStack(spacing: 0) {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 13, weight: .bold)).foregroundStyle(LiquidGlassColors.textPrimary)
                if let subtitle { Text(subtitle).font(.system(size: 11)).foregroundStyle(LiquidGlassColors.textSecondary) }
            }
            Spacer()
            trailing()
        }
        .padding(.horizontal, 24).padding(.vertical, 16)
        if showDivider { GlassDivider().padding(.horizontal, 24) }
    }
}

@ViewBuilder
func artisanToggle(isOn: Binding<Bool>) -> some View {
    Button { withAnimation(.gallerySpring) { isOn.wrappedValue.toggle() } } label: {
        ZStack {
            Capsule().fill(isOn.wrappedValue ? LiquidGlassColors.primaryPink : Color.white.opacity(0.1)).frame(width: 36, height: 20)
            Circle().fill(Color.white).frame(width: 16, height: 16).shadow(color: .black.opacity(0.2), radius: 2).offset(x: isOn.wrappedValue ? 8 : -8)
        }
    }.buttonStyle(.plain)
}

// MARK: - 高级子页
private struct AdvancedSettingsTab: View {
    var viewModel: SettingsViewModel
    @State private var displayManager = DisplayManager.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                artisanSettingsSection(header: "渲染实验室 (RENDERING LAB)") {
                    artisanSettingsRow(title: "垂直同步 V-Sync", subtitle: "将动态壁纸输出与显示刷新节奏对齐") {
                        artisanToggle(isOn: Binding(
                            get: { viewModel.settings?.vSyncEnabled ?? true },
                            set: { setVSyncEnabled($0) }
                        ))
                    }

                    artisanSettingsRow(title: "高负载自动降级", subtitle: "CPU/GPU 占用过高时自动暂停或降低帧率", showDivider: false) {
                        artisanToggle(isOn: Binding(
                            get: { viewModel.settings?.pauseOnHighLoad ?? true },
                            set: { setPauseOnHighLoad($0) }
                        ))
                    }
                }

                artisanSettingsSection(header: "深度暂停策略 (DEEP PAUSE STRATEGIES)") {
                    artisanSettingsRow(title: "失焦暂停", subtitle: "桌面不处于交互焦点时暂停渲染") {
                        artisanToggle(isOn: Binding(
                            get: { viewModel.settings?.pauseOnLostFocus ?? false },
                            set: { setPauseOnLostFocus($0) }
                        ))
                    }

                    artisanSettingsRow(title: "合盖暂停", subtitle: "笔记本合盖或外接模式切换时停止壁纸播放") {
                        artisanToggle(isOn: Binding(
                            get: { viewModel.settings?.pauseOnLidClosed ?? true },
                            set: { setPauseOnLidClosed($0) }
                        ))
                    }

                    artisanSettingsRow(title: "睡眠前暂停", subtitle: "系统进入睡眠前释放视频解码与渲染资源") {
                        artisanToggle(isOn: Binding(
                            get: { viewModel.settings?.pauseBeforeSleep ?? true },
                            set: { setPauseBeforeSleep($0) }
                        ))
                    }

                    artisanSettingsRow(title: "被遮挡时暂停", subtitle: "桌面被窗口完全覆盖时降低后台渲染消耗", showDivider: false) {
                        artisanToggle(isOn: Binding(
                            get: { viewModel.settings?.pauseOnOcclusion ?? false },
                            set: { setPauseOnOcclusion($0) }
                        ))
                    }
                }

                artisanSettingsSection(header: "专业音频路由 (PRO AUDIO ROUTING)") {
                    artisanSettingsRow(title: "主音频输出源", subtitle: "为多屏或演示场景指定壁纸音频输出策略", showDivider: false) {
                        Picker("", selection: Binding(
                            get: { viewModel.settings?.audioScreenId ?? "system" },
                            set: { setAudioScreenId($0) }
                        )) {
                            Text("跟随系统默认输出").tag("system")
                            ForEach(displayManager.availableScreens) { screen in
                                Text("\(screen.name) · \(screen.resolution)").tag(screen.id)
                            }
                        }
                        .frame(width: 180)
                    }
                }

                artisanSettingsSection(header: "界面实验项 (INTERFACE EXPERIMENTS)") {
                    artisanSettingsRow(title: "实验功能入口", subtitle: "为后续 Metal 渲染器、音频路由与多屏调度保留专业开关位", showDivider: false) {
                        Image(systemName: "testtube.2")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(LiquidGlassColors.primaryPink)
                    }
                }
            }
            .padding(.top, 32)
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }

    private func setVSyncEnabled(_ enabled: Bool) {
        viewModel.settings?.vSyncEnabled = enabled
        viewModel.save()
    }

    private func setPauseOnHighLoad(_ enabled: Bool) {
        viewModel.updatePauseStrategy(\.pauseOnHighLoad, enabled)
    }

    private func setPauseOnLostFocus(_ enabled: Bool) {
        viewModel.updatePauseStrategy(\.pauseOnLostFocus, enabled)
    }

    private func setPauseOnLidClosed(_ enabled: Bool) {
        viewModel.updatePauseStrategy(\.pauseOnLidClosed, enabled)
    }

    private func setPauseBeforeSleep(_ enabled: Bool) {
        viewModel.updatePauseStrategy(\.pauseBeforeSleep, enabled)
    }

    private func setPauseOnOcclusion(_ enabled: Bool) {
        viewModel.updatePauseStrategy(\.pauseOnOcclusion, enabled)
    }

    private func setAudioScreenId(_ id: String) {
        viewModel.settings?.audioScreenId = id
        viewModel.save()
    }
}

// MARK: - About 子页
private struct AboutSettingsTab: View {
    @State private var isHoveringWeb = false
    @State private var isHoveringGit = false

    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                // 品牌核心展示
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(LiquidGlassColors.primaryPink.opacity(0.15))
                            .frame(width: 120, height: 120)
                            .blur(radius: 20)
                        
                        Image(nsImage: NSApp.applicationIconImage ?? NSImage())
                            .resizable()
                            .frame(width: 80, height: 80)
                            .artisanShadow(radius: 24)
                    }
                    
                    VStack(spacing: 8) {
                        Text("PlumWallPaper")
                            .font(.custom("Georgia", size: 32).bold().italic())
                            .foregroundStyle(LiquidGlassColors.textPrimary)
                        
                        Text("CRAFTSMANSHIP EDITION")
                            .font(.system(size: 10, weight: .black))
                            .kerning(4)
                            .foregroundStyle(LiquidGlassColors.primaryPink)
                    }
                }
                .padding(.top, 20)

                // 品牌哲学描述
                VStack(spacing: 16) {
                    Text("数位艺术的策展人")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(LiquidGlassColors.textPrimary)
                    
                    Text("Plum 致力于打破桌面与艺术的边界。通过精密的粒子动力学与渲染调度，我们将每一帧静止的画面，转化为充满呼吸感的感官之旅。这不仅是一款壁纸引擎，更是您个人数字空间的艺术工作室。")
                        .font(.system(size: 13))
                        .lineSpacing(6)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(LiquidGlassColors.textSecondary)
                        .padding(.horizontal, 40)
                }

                // 交互磁贴
                HStack(spacing: 20) {
                    artisanLinkTile(
                        icon: "safari.fill",
                        title: "官方站点",
                        subtitle: "plumstudio.art",
                        isHovered: isHoveringWeb
                    ) {
                        isHoveringWeb = $0
                    } action: {
                        NSWorkspace.shared.open(URL(string: "https://plumstudio.art")!)
                    }

                    artisanLinkTile(
                        icon: "terminal.fill",
                        title: "开源社区",
                        subtitle: "GitHub Repos",
                        isHovered: isHoveringGit
                    ) {
                        isHoveringGit = $0
                    } action: {
                        NSWorkspace.shared.open(URL(string: "https://github.com")!)
                    }
                }
                .padding(.horizontal, 40)

                // 团队与版本信息
                VStack(spacing: 0) {
                    artisanSettingsRow(title: "当前版本", subtitle: "Version 1.0.2 (Build 20260502)") {
                        Text("已是最新").font(.system(size: 11, weight: .bold)).foregroundStyle(LiquidGlassColors.textQuaternary)
                    }
                    
                    artisanSettingsRow(title: "策展团队", subtitle: "Plum Studio & Global Artisans", showDivider: false) {
                        Image(systemName: "seal.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(LiquidGlassColors.primaryPink)
                    }
                }
                .galleryCardStyle(radius: 20, padding: 0)
                .padding(.horizontal, 40)

                // 版权脚注
                Text("COPYRIGHT © 2026 PLUM STUDIO. ALL RIGHTS RESERVED.")
                    .font(.system(size: 9, weight: .medium))
                    .kerning(1.5)
                    .foregroundStyle(LiquidGlassColors.textQuaternary)
                    .padding(.bottom, 40)
            }
        }
    }

    private func artisanLinkTile(icon: String, title: String, subtitle: String, isHovered: Bool, onHover: @escaping (Bool) -> Void, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(isHovered ? LiquidGlassColors.primaryPink : LiquidGlassColors.textSecondary)
                
                VStack(spacing: 2) {
                    Text(title).font(.system(size: 13, weight: .bold)).foregroundStyle(LiquidGlassColors.textPrimary)
                    Text(subtitle).font(.system(size: 10)).foregroundStyle(LiquidGlassColors.textQuaternary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(isHovered ? Color.white.opacity(0.06) : Color.white.opacity(0.02))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(isHovered ? LiquidGlassColors.primaryPink.opacity(0.3) : LiquidGlassColors.glassBorder, lineWidth: 1)
            )
            .onHover(perform: onHover)
            .animation(.gallerySpring, value: isHovered)
        }
        .buttonStyle(.plain)
    }
}
