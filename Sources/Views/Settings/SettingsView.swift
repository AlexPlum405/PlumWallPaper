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
        case .audio: AudioTab(viewModel: viewModel)
        case .performance: PerformanceTab(viewModel: viewModel)
        case .appRules: AppRulesTabV2(viewModel: viewModel, toast: $toast)
        case .slideshow: SlideshowTab(viewModel: viewModel)
        case .display: DisplayTab(viewModel: viewModel)
        case .shortcuts: ShortcutsTab()
        case .appearance: AppearanceTab(viewModel: viewModel)
        case .library: LibraryTab(viewModel: viewModel)
        case .about: AboutSettingsTab()
        }
    }
}

// MARK: - 设置标签枚举 (完全补全版)
private enum SettingsTab: String, CaseIterable, Identifiable {
    case general, playback, audio, performance, appRules, slideshow, display, shortcuts, appearance, library, about
    var id: Self { self }
    var title: String {
        switch self {
        case .general: return "通用"
        case .playback: return "渲染"
        case .audio: return "音效"
        case .performance: return "性能"
        case .appRules: return "智能暂停"
        case .slideshow: return "轮播"
        case .display: return "显示器"
        case .shortcuts: return "快捷键"
        case .appearance: return "界面"
        case .library: return "存储"
        case .about: return "关于"
        }
    }
    var icon: String {
        switch self {
        case .general: return "command"
        case .playback: return "play.circle.fill"
        case .audio: return "speaker.wave.3.fill"
        case .performance: return "gauge.medium"
        case .appRules: return "bolt.shield.fill"
        case .slideshow: return "arrow.2.squarepath"
        case .display: return "display.2"
        case .shortcuts: return "keyboard"
        case .appearance: return "paintpalette.fill"
        case .library: return "archivebox.fill"
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

// MARK: - About 子页
private struct AboutSettingsTab: View {
    var body: some View {
        VStack(spacing: 32) {
            Image(nsImage: NSApp.applicationIconImage ?? NSImage()).resizable().frame(width: 80, height: 80).artisanShadow()
            VStack(spacing: 8) {
                Text("PlumWallPaper").font(.custom("Georgia", size: 28).bold())
                Text("CRAFTSMANSHIP EDITION v1.0.2").font(.system(size: 10, weight: .black)).kerning(2).foregroundStyle(LiquidGlassColors.textQuaternary)
            }
            artisanSettingsSection(header: "溯源") {
                HStack {
                    Text("策展团队").font(.system(size: 13, weight: .bold))
                    Spacer()
                    Text("Plum Studio").font(.system(size: 13, weight: .medium)).foregroundStyle(LiquidGlassColors.textSecondary)
                }.padding(20)
            }
        }
    }
}
