import SwiftUI

struct PlaybackTab: View {
    var viewModel: SettingsViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // MARK: - [播放引擎控制]
                artisanSettingsSection(header: "播放引擎控制 (ENGINE CONTROL)") {
                    artisanSettingsRow(title: "循环模式", subtitle: "设置作品播放完毕后的物理行为") {
                        Picker("", selection: Binding(
                            get: { viewModel.settings?.loopMode ?? .loop },
                            set: { setLoopMode($0) }
                        )) {
                            Text("循环播放").tag(LoopMode.loop)
                            Text("播放一次").tag(LoopMode.once)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 160)
                    }

                    artisanSettingsRow(title: "播放速率", subtitle: "调整视频或动画的流逝感 (\(String(format: "%.1fx", viewModel.settings?.playbackRate ?? 1.0)))") {
                        Slider(value: Binding(
                            get: { viewModel.settings?.playbackRate ?? 1.0 },
                            set: { setPlaybackRate($0) }
                        ), in: 0.5...2.0, step: 0.1)
                        .tint(LiquidGlassColors.primaryPink)
                        .frame(width: 160)
                    }

                    artisanSettingsRow(title: "随机起始位置", subtitle: "每次开启时从随机时间戳开始播放", showDivider: false) {
                        artisanToggle(isOn: Binding(
                            get: { viewModel.settings?.randomStartPosition ?? false },
                            set: { setRandomStartPosition($0) }
                        ))
                    }
                }

                // MARK: - [音频混音]
                artisanSettingsSection(header: "音频混音 (AUDIO MIXING)") {
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
                            .frame(width: 120)
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

                    artisanSettingsRow(title: "每张壁纸独立音量", subtitle: "允许单个作品覆盖全局音量设定", showDivider: false) {
                        Image(systemName: "slider.horizontal.2.square")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(LiquidGlassColors.primaryPink)
                    }
                }
            }
            .padding(.top, 32)
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }
}
