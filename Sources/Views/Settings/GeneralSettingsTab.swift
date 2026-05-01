import SwiftUI

struct GeneralSettingsTab: View {
    var viewModel: SettingsViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                artisanSettingsSection(header: "系统与视界 (SYSTEM & VISION)") {
                    artisanSettingsRow(title: "界面展示语言", subtitle: "设置应用程序的展示文字规范") {
                        HStack(spacing: 4) {
                            Text("简体中文").font(.system(size: 13, weight: .bold)).foregroundStyle(LiquidGlassColors.primaryPink)
                            Image(systemName: "chevron.up.chevron.down").font(.system(size: 10)).foregroundStyle(LiquidGlassColors.textQuaternary)
                        }
                    }

                    artisanSettingsRow(title: "开机自动启动", subtitle: "登录系统时自动运行 PlumStudio") {
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

                artisanSettingsSection(header: "艺术呈现参数") {
                    artisanSettingsRow(title: "壁纸渲染透明度", subtitle: "调整桌面壁纸的整体物理透明感") {
                        HStack(spacing: 12) {
                            Text("\(viewModel.settings?.wallpaperOpacity ?? 100)%")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundStyle(LiquidGlassColors.primaryPink)
                                .frame(width: 40)
                            
                            Slider(value: Binding(
                                get: { Double(viewModel.settings?.wallpaperOpacity ?? 100) },
                                set: { setWallpaperOpacity(Int($0)) }
                            ), in: 0...100, step: 1)
                            .tint(LiquidGlassColors.primaryPink)
                            .frame(width: 140)
                        }
                    }

                    artisanSettingsRow(title: "胶片颗粒效果", subtitle: "为用户界面注入怀旧的胶片呼吸感", showDivider: false) {
                        artisanToggle(isOn: .constant(true))
                    }
                }
            }
            .padding(.top, 32)
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }
}
