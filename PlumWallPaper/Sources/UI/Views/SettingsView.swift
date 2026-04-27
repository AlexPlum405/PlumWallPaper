import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [Settings]

    @State private var selection: String? = "通用"

    var currentSettings: Settings? { settings.first }

    let navItems = [
        ("通用", "sidebar.left"),
        ("性能", "bolt.fill"),
        ("显示", "display.2"),
        ("库管理", "square.stack.3d.up.fill"),
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
            .listStyle(.sidebar)
            .padding(.top, 100)
            .background(Color(red: 20/255, green: 21/255, blue: 26/255))
        } detail: {
            ZStack {
                Theme.bg.ignoresSafeArea()

                if let selection, let config = currentSettings {
                    ScrollView(showsIndicators: false) {
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

struct GeneralSettingsView: View {
    @Bindable var settings: Settings

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
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
                ToggleRow(title: "垂直同步 (V-Sync)", desc: "防止画面撕裂", isOn: $settings.vSyncEnabled)
                Divider().background(Theme.border)
                ToggleRow(title: "预解码技术", desc: "预先加载下一张壁纸，无缝过渡", isOn: $settings.preDecodeEnabled)
                Divider().background(Theme.border)
                ToggleRow(title: "Audio Ducking", desc: "多媒体避让，降低壁纸音频干扰", isOn: $settings.audioDuckingEnabled)
            }

            SettingsGroup(label: "智能暂停策略 (SMART PAUSE)") {
                VStack(spacing: 16) {
                    ToggleRow(title: "电池供电时暂停", desc: "延长续航", isOn: $settings.pauseOnBattery)
                    ToggleRow(title: "全屏应用时暂停", desc: "专注工作时停止渲染", isOn: $settings.pauseOnFullscreen)
                    ToggleRow(title: "遮挡时暂停", desc: "被遮挡时自动休眠", isOn: $settings.pauseOnOcclusion)
                    ToggleRow(title: "低电量时暂停", desc: "系统省电模式触发", isOn: $settings.pauseOnLowBattery)
                    ToggleRow(title: "屏幕共享时暂停", desc: "共享时节省资源", isOn: $settings.pauseOnScreenSharing)
                    ToggleRow(title: "合盖模式暂停", desc: "笔记本合盖时停止渲染", isOn: $settings.pauseOnLidClosed)
                    ToggleRow(title: "高负载时暂停", desc: "CPU/GPU 过高时自动避让", isOn: $settings.pauseOnHighLoad)
                    ToggleRow(title: "失去焦点暂停", desc: "应用失去焦点时暂停", isOn: $settings.pauseOnLostFocus)
                    ToggleRow(title: "睡眠预停", desc: "进入睡眠前停止渲染", isOn: $settings.pauseBeforeSleep)
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
                    MonitorModel(name: "Studio Display", res: "5120×2880", isMain: true)
                    MonitorModel(name: "MacBook Pro", res: "3456×2234", isMain: false)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(Color.black.opacity(0.3))
                .cornerRadius(28)

                Picker("拓扑模式", selection: $settings.displayTopology) {
                    Text("独立渲染").tag(DisplayTopology.independent)
                    Text("镜像显示").tag(DisplayTopology.mirror)
                    Text("全景拼接").tag(DisplayTopology.panorama)
                }
                .pickerStyle(.segmented)
                .padding(.top, 20)

                Picker("色彩空间", selection: $settings.colorSpace) {
                    Text("Display P3").tag(ColorSpace.p3)
                    Text("sRGB").tag(ColorSpace.srgb)
                    Text("Adobe RGB").tag(ColorSpace.adobeRGB)
                }
                .pickerStyle(.segmented)
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
                Divider().background(Theme.border)
                HStack {
                    Text("缓存阈值")
                    Spacer()
                    Text(ByteCountFormatter.string(fromByteCount: settings.cacheThreshold, countStyle: .file))
                        .foregroundColor(.white.opacity(0.5))
                }
                Divider().background(Theme.border)
                ToggleRow(title: "自动清理缓存", desc: "超过阈值时自动删除旧缓存", isOn: $settings.autoCleanEnabled)
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
                    Text("跟随系统").tag(ThemeMode.auto)
                    Text("浅色").tag(ThemeMode.light)
                    Text("深色").tag(ThemeMode.dark)
                }
                .pickerStyle(.segmented)

                Divider().background(Theme.border)
                ToggleRow(title: "启用动画", desc: "界面过渡与悬浮动画", isOn: $settings.animationsEnabled)
            }
        }
    }
}

struct AboutSettingsView: View {
    var body: some View {
        VStack(alignment: .center, spacing: 32) {
            Image(systemName: "sparkles.tv")
                .font(.system(size: 80))
                .foregroundColor(Theme.accent)

            VStack(spacing: 8) {
                Text("PlumWallPaper")
                    .font(Theme.Fonts.display(size: 32))
                Text("Version 1.0.0 (Build 2026.04.28)")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.4))
            }

            Button("检查更新...") {}
                .buttonStyle(.borderedProminent)
                .tint(Theme.accent)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }
}

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
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                Text(desc)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.4))
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: Theme.accent))
        }
    }
}

struct MonitorModel: View {
    let name: String
    let res: String
    let isMain: Bool

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black)
                    .frame(width: isMain ? 180 : 140, height: isMain ? 112 : 88)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isMain ? Theme.accent : Color.white.opacity(0.1), lineWidth: 2)
                    )
                Image(systemName: "display")
                    .opacity(0.2)
            }
            VStack(spacing: 4) {
                Text(name)
                    .font(.system(size: 13, weight: .bold))
                Text(res)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.3))
            }
        }
    }
}
