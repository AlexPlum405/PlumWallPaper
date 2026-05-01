import SwiftUI

struct PlaybackTab: View {
    var viewModel: SettingsViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                artisanSettingsSection(header: "播放引擎控制") {
                    artisanSettingsRow(title: "循环模式", subtitle: "设置内容播放结束后的自动行为") {
                        Picker("", selection: Binding(
                            get: { viewModel.settings?.loopMode ?? .loop },
                            set: { setLoopMode($0) }
                        )) {
                            Text("循环播放").tag(LoopMode.loop)
                            Text("播放一次").tag(LoopMode.once)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 180)
                    }

                    artisanSettingsRow(title: "播放速率", subtitle: "调节动态内容的渲染速度") {
                        HStack(spacing: 12) {
                            Text("\(String(format: "%.1f", viewModel.settings?.playbackRate ?? 1.0))x")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundStyle(LiquidGlassColors.primaryPink)
                                .frame(width: 40, alignment: .trailing)

                            Slider(value: Binding(
                                get: { viewModel.settings?.playbackRate ?? 1.0 },
                                set: { setPlaybackRate($0) }
                            ), in: 0.5...2.0, step: 0.1)
                            .tint(LiquidGlassColors.primaryPink)
                            .frame(width: 160)
                        }
                    }

                    artisanSettingsRow(title: "随机起始位置", subtitle: "每次切换壁纸时从随机时间点开始", showDivider: false) {
                        artisanToggle(isOn: Binding(
                            get: { viewModel.settings?.randomStartPosition ?? false },
                            set: { setRandomStartPosition($0) }
                        ))
                    }
                }
                
                // 占位提示
                VStack(spacing: 8) {
                    Image(systemName: "info.circle").font(.system(size: 14)).foregroundStyle(LiquidGlassColors.textQuaternary)
                    Text("播放速率调整可能受限于具体的壁纸引擎类型。").font(.system(size: 11)).foregroundStyle(LiquidGlassColors.textQuaternary)
                }.padding(.top, 20)
            }
            .padding(.top, 32)
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }
}
