import SwiftUI

struct GeneralSettingsTab: View {
    var viewModel: SettingsViewModel
    @State private var isShortcutsExpanded: Bool = false
    @State private var recordingKey: String? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // MARK: - [系统与视界]
                artisanSettingsSection(header: "系统与视界 (SYSTEM & VISION)") {
                    artisanSettingsRow(title: "界面展示语言", subtitle: "设置应用程序的展示文字规范") {
                        HStack(spacing: 4) {
                            Text("简体中文").font(.system(size: 13, weight: .bold)).foregroundStyle(LiquidGlassColors.primaryPink)
                            Image(systemName: "chevron.up.chevron.down").font(.system(size: 10)).foregroundStyle(LiquidGlassColors.textQuaternary)
                        }
                    }

                    artisanSettingsRow(title: "开机自动启动", subtitle: "登录系统时自动运行 Plum Studio") {
                        artisanToggle(isOn: Binding(
                            get: { viewModel.settings?.launchAtLogin ?? true },
                            set: { setLaunchAtLogin($0) }
                        ))
                    }

                    artisanSettingsRow(title: "驻留菜单栏", subtitle: "在系统顶部状态栏显示快速控制图标", showDivider: false) {
                        artisanToggle(isOn: Binding(
                            get: { viewModel.settings?.menuBarEnabled ?? true },
                            set: { setMenuBarEnabled($0) }
                        ))
                    }
                }

                // MARK: - [资源存储]
                artisanSettingsSection(header: "资源存储 (RESOURCES & STORAGE)") {
                    artisanSettingsRow(title: "资源存储主路径", subtitle: viewModel.settings?.libraryPath ?? "~/Pictures/PlumLibrary") {
                        Button(action: { changeLibraryPath() }) {
                            Text("更改路径")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(LiquidGlassColors.primaryPink)
                                .padding(.horizontal, 14).padding(.vertical, 6)
                                .galleryCardStyle(radius: 8, padding: 0)
                        }
                        .buttonStyle(.plain)
                    }

                    artisanSettingsRow(title: "缓存空间管理", subtitle: "优化加载性能并释放多余磁盘占用", showDivider: false) {
                        Button(action: { clearCache() }) {
                            Text("清理缓存")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(LiquidGlassColors.errorRed)
                                .padding(.horizontal, 14).padding(.vertical, 6)
                                .galleryCardStyle(radius: 8, padding: 0)
                        }
                        .buttonStyle(.plain)
                    }
                }

                // MARK: - [全局快捷键]
                VStack(alignment: .leading, spacing: 16) {
                    Button {
                        withAnimation(.gallerySpring) { isShortcutsExpanded.toggle() }
                    } label: {
                        HStack {
                            Text("全局快捷键 (GLOBAL HOTKEYS)")
                                .font(.system(size: 10, weight: .black))
                                .kerning(2.5)
                                .foregroundStyle(LiquidGlassColors.textQuaternary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(LiquidGlassColors.textQuaternary)
                                .rotationEffect(.degrees(isShortcutsExpanded ? 180 : 0))
                        }
                        .padding(.leading, 4)
                        .padding(.trailing, 8)
                    }
                    .buttonStyle(.plain)

                    if isShortcutsExpanded {
                        VStack(spacing: 0) {
                            shortcutRow(id: "toggle", title: "播放 / 暂停", current: "⌘ ⌥ P")
                            shortcutRow(id: "prev", title: "上一张壁纸", current: "⌘ ⌥ [")
                            shortcutRow(id: "next", title: "下一张壁纸", current: "⌘ ⌥ ]")
                            shortcutRow(id: "settings", title: "打开设置中心", current: "⌘ ⌥ S")
                            shortcutRow(id: "library", title: "打开本地", current: "⌘ ⌥ L", showDivider: false)
                        }
                        .galleryCardStyle(radius: 20, padding: 0)
                        .transition(.move(edge: .top).combined(with: .opacity))

                        Button(action: { resetAllShortcuts() }) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.counterclockwise")
                                Text("重置所有快捷键")
                            }
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(LiquidGlassColors.errorRed.opacity(0.8))
                            .padding(.horizontal, 20)
                            .frame(height: 38)
                            .galleryCardStyle(radius: 19, padding: 0)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 8)
                    }
                }
            }
            .padding(.top, 32)
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }

    private func shortcutRow(id: String, title: String, current: String, showDivider: Bool = true) -> some View {
        artisanSettingsRow(title: title, subtitle: "全局有效，即使应用在后台", showDivider: showDivider) {
            Button {
                withAnimation(.gallerySpring) {
                    recordingKey = (recordingKey == id) ? nil : id
                }
            } label: {
                ZStack {
                    if recordingKey == id {
                        Text("请按下快捷键...")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(LiquidGlassColors.primaryPink)
                            .padding(.horizontal, 12)
                            .frame(minWidth: 100, minHeight: 28)
                            .background(Capsule().fill(LiquidGlassColors.primaryPink.opacity(0.1)))
                            .overlay(Capsule().stroke(LiquidGlassColors.primaryPink.opacity(0.3), lineWidth: 1))
                    } else {
                        HStack(spacing: 8) {
                            Text(current)
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundStyle(LiquidGlassColors.textSecondary)
                            
                            Image(systemName: "keyboard")
                                .font(.system(size: 10))
                                .foregroundStyle(LiquidGlassColors.textQuaternary)
                        }
                        .padding(.horizontal, 12)
                        .frame(minWidth: 100, minHeight: 28)
                        .background(Capsule().fill(Color.white.opacity(0.04)))
                        .overlay(Capsule().stroke(Color.white.opacity(0.08), lineWidth: 1))
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }
}
