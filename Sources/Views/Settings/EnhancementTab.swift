import SwiftUI

struct EnhancementTab: View {
    var viewModel: SettingsViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                artisanSettingsSection(header: "超分辨率 (SUPER RESOLUTION)") {
                    artisanSettingsRow(title: "启用超分辨率", subtitle: "对低分辨率壁纸做 GPU 放大增强") {
                        artisanToggle(isOn: Binding(
                            get: { viewModel.settings?.superResolutionEnabled ?? false },
                            set: { setSuperResolutionEnabled($0) }
                        ))
                    }

                    artisanSettingsRow(title: "放大倍数", subtitle: "2x / 3x / 4x", showDivider: false) {
                        Picker("", selection: Binding(
                            get: { viewModel.settings?.superResolutionScale ?? 2 },
                            set: { setSuperResolutionScale($0) }
                        )) {
                            Text("2x").tag(2)
                            Text("3x").tag(3)
                            Text("4x").tag(4)
                        }
                        .frame(width: 120)
                        .disabled(!(viewModel.settings?.superResolutionEnabled ?? false))
                    }
                }

                artisanSettingsSection(header: "视频增强 (VIDEO ENHANCEMENT)") {
                    artisanSettingsRow(title: "启用 VideoToolbox 加速", subtitle: "减少动态壁纸 CPU 开销", showDivider: false) {
                        artisanToggle(isOn: Binding(
                            get: { viewModel.settings?.videoEnhancementEnabled ?? false },
                            set: { setVideoEnhancementEnabled($0) }
                        ))
                    }
                }

                artisanSettingsSection(header: "状态栏显示 (STATUS BAR)") {
                    artisanSettingsRow(title: "显示 FPS", subtitle: "在菜单栏面板中显示帧率") {
                        artisanToggle(isOn: Binding(
                            get: { viewModel.settings?.statusBarShowFPS ?? true },
                            set: { setStatusBarShowFPS($0) }
                        ))
                    }

                    artisanSettingsRow(title: "显示内存", subtitle: "在菜单栏面板中显示内存占用") {
                        artisanToggle(isOn: Binding(
                            get: { viewModel.settings?.statusBarShowMemory ?? true },
                            set: { setStatusBarShowMemory($0) }
                        ))
                    }

                    artisanSettingsRow(title: "显示 GPU", subtitle: "在菜单栏面板中显示 GPU 占用", showDivider: false) {
                        artisanToggle(isOn: Binding(
                            get: { viewModel.settings?.statusBarShowGPU ?? true },
                            set: { setStatusBarShowGPU($0) }
                        ))
                    }
                }
            }
            .padding(.top, 32)
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }
}
