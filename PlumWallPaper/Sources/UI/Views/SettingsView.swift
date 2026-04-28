import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [Settings]
    
    @State private var selection: String? = "通用"
    
    var currentSettings: Settings? { settings.first }
    
    let navItems = [
        ("通用", "sidebar.left"),
        ("性能", "bolt.fill"),
        ("显示", "monitor"),
        ("库管理", "layers.fill"),
        ("外观", "paintbrush.fill"),
        ("关于", "info.circle.fill")
    ]
    
    var body: some View {
        NavigationSplitView {
            List(navItems, id: \.0, selection: $selection) { item in
                NavigationLink(value: item.0) {
                    Label(item.0, systemImage: item.1)
                        .font(.system(size: 14, weight: .bold))
                }
                .padding(.vertical, 4)
            }
            .listStyle(SidebarListStyle())
            .padding(.top, 100)
            .background(Color(red: 20/255, green: 21/255, blue: 26/255))
        } detail: {
            ZStack(alignment: .topTrailing) {
                Theme.bg.edgesIgnoringSafeArea(.all)

                if let selection = selection, let config = currentSettings {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 56) {
                            Text(selection)
                                .font(Theme.Fonts.display(size: 42))
                                .italic()
                                .padding(.top, 116)
                            
                            switch selection {
                            case "通用": GeneralSettingsView(settings: config)
                            case "性能": PerformanceSettingsView(settings: config)
                            case "显示": DisplaySettingsView(settings: config)
                            case "库管理": LibrarySettingsView(settings: config)
                            case "外观": AppearanceSettingsView(settings: config)
                            case "关于": AboutSettingsView()
                            default: EmptyView()
                            }
                        }
                        .padding(.horizontal, 72)
                        .padding(.bottom, 80)
                    }
                } else {
                    ProgressView()
                }

                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(10)
                        .background(Theme.glass)
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
                .padding(24)
            }
        }
        .onAppear {
            if settings.isEmpty {
                let defaultSettings = Settings()
                modelContext.insert(defaultSettings)
                try? modelContext.save()
            }
        }
    }
}

// --- 子视图组件 ---

struct GeneralSettingsView: View {
    @Bindable var settings: Settings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 40) {
            SettingsGroup(label: "自动化") {
                ToggleRow(title: "开机自动启动", desc: "在系统登录时自动开启 PlumWallPaper", isOn: .constant(true))
                Divider().background(Theme.border)
                ToggleRow(title: "静默运行", desc: "启动时不显示主界面，仅在菜单栏常驻", isOn: .constant(false))
            }
            
            SettingsGroup(label: "轮播设置 (SLIDESHOW)") {
                ToggleRow(title: "启用轮播", desc: "自动按间隔切换壁纸库中的作品", isOn: $settings.slideshowEnabled)
                
                if settings.slideshowEnabled {
                    HStack {
                        Text("切换间隔").font(.system(size: 14))
                        Spacer()
                        Picker("", selection: $settings.slideshowInterval) {
                            Text("1 分钟").tag(TimeInterval(60))
                            Text("5 分钟").tag(TimeInterval(300))
                            Text("30 分钟").tag(TimeInterval(1800))
                            Text("1 小时").tag(TimeInterval(3600))
                            Text("每天").tag(TimeInterval(86400))
                        }
                        .frame(width: 120)
                    }
                }
            }
        }
    }
}

struct PerformanceSettingsView: View {
    @Bindable var settings: Settings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 48) {
            SettingsGroup(label: "核心渲染") {
                ToggleRow(title: "垂直同步 (V-Sync)", desc: "防止画面撕裂，但在高刷屏下可能增加能耗", isOn: $settings.vSyncEnabled)
                Divider().background(Theme.border)
                ToggleRow(title: "预解码技术", desc: "预先加载下一张壁纸，实现无缝过渡", isOn: $settings.preDecodeEnabled)
                Divider().background(Theme.border)
                ToggleRow(title: "音频鸭入 (Audio Ducking)", desc: "当其他应用播放声音时，自动降低壁纸音量", isOn: $settings.audioDuckingEnabled)
            }
            
            SettingsGroup(label: "智能暂停策略 (SMART PAUSE)") {
                VStack(spacing: 16) {
                    ToggleRow(title: "电池供电时暂停", desc: "有效延长笔记本续航时间", isOn: $settings.pauseOnBattery)
                    ToggleRow(title: "全屏应用时暂停", desc: "专注于全屏工作或游戏时停止渲染", isOn: $settings.pauseOnFullscreen)
                    ToggleRow(title: "遮挡时暂停", desc: "当壁纸被完全遮挡时自动休眠渲染引擎", isOn: $settings.pauseOnOcclusion)
                    ToggleRow(title: "低电量时暂停", desc: "系统触发低电量警报时自动停止", isOn: $settings.pauseOnLowBattery)
                    ToggleRow(title: "屏幕共享时暂停", desc: "避免在会议中泄露壁纸内容", isOn: $settings.pauseOnScreenSharing)
                    ToggleRow(title: "合盖模式暂停", desc: "连接外屏但合上盖子时停止内置屏渲染", isOn: $settings.pauseOnLidClosed)
                    ToggleRow(title: "高负载应用暂停", desc: "当系统 CPU/GPU 负载过高时让出资源", isOn: $settings.pauseOnHighLoad)
                    ToggleRow(title: "失去焦点暂停", desc: "桌面非活跃状态时立即暂停", isOn: $settings.pauseOnLostFocus)
                    ToggleRow(title: "睡眠前暂停", desc: "在系统进入待机前提前释放显存", isOn: $settings.pauseBeforeSleep)
                }
            }
        }
    }
}

struct DisplaySettingsView: View {
    @Bindable var settings: Settings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 40) {
            SettingsGroup(label: "显示器配置") {
                HStack(spacing: 40) {
                    MonitorCard(name: "Studio Display", res: "5120×2880", isMain: true)
                    MonitorCard(name: "MacBook Pro", res: "3456×2234", isMain: false)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(Color.black.opacity(0.3))
                .cornerRadius(20)
                
                Picker("拓扑模式", selection: $settings.displayTopology) {
                    Text("独立渲染").tag(DisplayTopology.independent)
                    Text("镜像显示").tag(DisplayTopology.mirrored)
                    Text("跨屏拉伸").tag(DisplayTopology.panorama)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.top, 20)
            }
        }
    }
}

struct LibrarySettingsView: View {
    @Bindable var settings: Settings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 40) {
            SettingsGroup(label: "存储路径") {
                HStack {
                    Text(settings.libraryPath)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(.white.opacity(0.5))
                    Spacer()
                    Button("更改路径...") {}
                        .buttonStyle(.bordered)
                }
            }
            
            SettingsGroup(label: "维护管理") {
                ToggleRow(title: "自动清理缓存", desc: "当缓存超过阈值时自动移除最旧的预览文件", isOn: $settings.autoCleanEnabled)
                if settings.autoCleanEnabled {
                    HStack {
                        Text("缓存上限").font(.system(size: 14))
                        Spacer()
                        Slider(value: .constant(5.0), in: 1...20)
                            .frame(width: 200)
                        Text("5.0 GB").font(.system(size: 13, weight: .bold))
                    }
                }
            }
        }
    }
}

struct AppearanceSettingsView: View {
    @Bindable var settings: Settings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 40) {
            SettingsGroup(label: "视觉风格") {
                Picker("主题模式", selection: $settings.themeMode) {
                    Text("跟随系统").tag(ThemeMode.system)
                    Text("深色").tag(ThemeMode.dark)
                    Text("浅色").tag(ThemeMode.light)
                }
                .pickerStyle(SegmentedPickerStyle())
                
                HStack {
                    Text("强调色").font(.system(size: 14))
                    Spacer()
                    Circle().fill(Theme.accent).frame(width: 24, height: 24)
                }
            }
            
            SettingsGroup(label: "动效") {
                ToggleRow(title: "启用界面动画", desc: "减弱转场和 UI 交互动效以提升响应度", isOn: $settings.animationsEnabled)
            }
        }
    }
}

struct AboutSettingsView: View {
    var body: some View {
        VStack(alignment: .center, spacing: 32) {
            Image(systemName: "plum.fill") // Replace with actual logo
                .font(.system(size: 80))
                .foregroundColor(Theme.accent)
            
            VStack(spacing: 8) {
                Text("PlumWallPaper")
                    .font(Theme.Fonts.display(size: 32))
                Text("Version 1.0.0 (Build 2026.04.28)")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.4))
            }
            
            Button("检查更新...") {
                // TODO: Update logic
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.accent)
            
            Text("© 2026 Alex AI. All rights reserved.")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.2))
                .padding(.top, 40)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }
}

// --- 辅助组件 ---

struct SettingsGroup<Content: View>: View {
    let label: String
    let content: Content
    
    init(label: String, @ViewBuilder content: () -> Content) {
        self.label = label
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(label)
                .font(.system(size: 11, weight: .black))
                .tracking(2)
                .foregroundColor(.white.opacity(0.3))
            
            content
        }
    }
}

struct ToggleRow: View {
    let title: String
    let desc: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 14, weight: .bold))
                Text(desc).font(.system(size: 12)).foregroundColor(.white.opacity(0.4))
            }
            Spacer()
            Toggle("", isOn: $isOn).toggleStyle(SwitchToggleStyle(tint: Theme.accent))
        }
    }
}

struct MonitorCard: View {
    let name: String
    let res: String
    let isMain: Bool

    var body: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 8)
                .stroke(isMain ? Theme.accent : Color.white.opacity(0.2), lineWidth: isMain ? 2 : 1)
                .frame(width: 80, height: 50)
                .overlay(
                    Text(isMain ? "主" : "副")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(isMain ? Theme.accent : .white.opacity(0.4))
                )
            Text(name)
                .font(.system(size: 12, weight: .semibold))
            Text(res)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.white.opacity(0.4))
        }
    }
}
