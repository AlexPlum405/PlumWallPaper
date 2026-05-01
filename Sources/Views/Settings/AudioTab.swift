import SwiftUI

struct AudioTab: View {
    var viewModel: SettingsViewModel
    
    // 模拟屏幕列表逻辑
    private let mockScreens = [
        (id: "built-in", name: "内建显示器"),
        (id: "external-1", name: "Studio Display"),
        (id: "external-2", name: "LG UltraFine")
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                artisanSettingsSection(header: "混音与输出") {
                    artisanSettingsRow(title: "全局音量", subtitle: "设置壁纸背景音频的默认输出级") {
                        HStack(spacing: 12) {
                            Text("\(viewModel.settings?.globalVolume ?? 50)%")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundStyle(LiquidGlassColors.primaryPink)
                                .frame(width: 40)
                            
                            Slider(value: Binding(
                                get: { Double(viewModel.settings?.globalVolume ?? 50) },
                                set: { setGlobalVolume(Int($0)) }
                            ), in: 0...100, step: 1)
                            .tint(LiquidGlassColors.primaryPink)
                            .frame(width: 140)
                        }
                    }

                    artisanSettingsRow(title: "默认静音", subtitle: "启动时自动关闭所有壁纸声音") {
                        artisanToggle(isOn: Binding(
                            get: { viewModel.settings?.defaultMuted ?? false },
                            set: { setDefaultMuted($0) }
                        ))
                    }

                    artisanSettingsRow(title: "仅预览音频", subtitle: "仅在预览窗口播放音频，桌面背景保持静默") {
                        artisanToggle(isOn: Binding(
                            get: { viewModel.settings?.previewOnlyAudio ?? true },
                            set: { setPreviewOnlyAudio($0) }
                        ))
                    }

                    artisanSettingsRow(title: "音频自动闪避", subtitle: "当其他应用播放音频时自动降低壁纸音量") {
                        artisanToggle(isOn: Binding(
                            get: { viewModel.settings?.audioDuckingEnabled ?? true },
                            set: { setAudioDuckingEnabled($0) }
                        ))
                    }

                    artisanSettingsRow(title: "主音频输出源", subtitle: "选择指定的显示器通道进行音频渲染", showDivider: false) {
                        Picker("", selection: Binding(
                            get: { viewModel.settings?.audioScreenId ?? "built-in" },
                            set: { setAudioScreenId($0) }
                        )) {
                            ForEach(mockScreens, id: \.id) { screen in
                                Text(screen.name).tag(screen.id)
                            }
                        }
                        .frame(width: 160)
                    }
                }
            }
            .padding(.top, 32)
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }
}
