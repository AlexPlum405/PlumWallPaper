import SwiftUI
import SwiftData

struct PlaybackTab: View {
    var viewModel: SettingsViewModel
    @Query(sort: \Tag.name) private var existingTags: [Tag]
    @State private var isSlideshowExpanded = true

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // MARK: - [自动轮播]
                artisanSettingsSection(header: "自动轮播 (SLIDESHOW)") {
                    artisanSettingsRow(title: "启用自动轮播", subtitle: "按规则自动切换桌面壁纸", showDivider: viewModel.settings?.slideshowEnabled ?? false) {
                        artisanToggle(isOn: Binding(
                            get: { viewModel.settings?.slideshowEnabled ?? false },
                            set: { setSlideshowEnabled($0) }
                        ))
                    }

                    if viewModel.settings?.slideshowEnabled ?? false {
                        Button {
                            withAnimation(.gallerySpring) { isSlideshowExpanded.toggle() }
                        } label: {
                            HStack {
                                Label("轮播规则", systemImage: "slider.horizontal.3")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(LiquidGlassColors.textSecondary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 10, weight: .bold))
                                    .rotationEffect(.degrees(isSlideshowExpanded ? 180 : 0))
                                    .foregroundStyle(LiquidGlassColors.textQuaternary)
                            }
                            .padding(.horizontal, 24)
                            .frame(height: 44)
                            .background(Color.white.opacity(0.02))
                        }
                        .buttonStyle(.plain)

                        if isSlideshowExpanded {
                            VStack(spacing: 0) {
                                artisanSettingsRow(title: "轮播间隔", subtitle: "每次切换之间的时间跨度") {
                                    HStack(spacing: 12) {
                                        Text(formatInterval(viewModel.settings?.slideshowInterval ?? 3600))
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundStyle(LiquidGlassColors.primaryPink)
                                            .frame(width: 60)
                                        Slider(value: Binding(
                                            get: { viewModel.settings?.slideshowInterval ?? 3600 },
                                            set: { setSlideshowInterval($0) }
                                        ), in: 60...7200, step: 60)
                                        .tint(LiquidGlassColors.primaryPink)
                                        .frame(width: 110)
                                    }
                                }

                                artisanSettingsRow(title: "播放顺序", subtitle: "决定作品出现逻辑") {
                                    Picker("", selection: Binding(
                                        get: { viewModel.settings?.slideshowOrder ?? .random },
                                        set: { setSlideshowOrder($0) }
                                    )) {
                                        Text("顺序").tag(SlideshowOrder.sequential)
                                        Text("随机").tag(SlideshowOrder.random)
                                        Text("收藏优先").tag(SlideshowOrder.favoritesFirst)
                                    }
                                    .pickerStyle(.segmented)
                                    .frame(width: 190)
                                }

                                artisanSettingsRow(title: "资源来源", subtitle: "限定自动轮播范围", showDivider: viewModel.settings?.slideshowSource == .tag) {
                                    Picker("", selection: Binding(
                                        get: { viewModel.settings?.slideshowSource ?? .all },
                                        set: { setSlideshowSource($0) }
                                    )) {
                                        Text("全部").tag(SlideshowSource.all)
                                        Text("收藏").tag(SlideshowSource.favorites)
                                        Text("标签").tag(SlideshowSource.tag)
                                    }
                                    .pickerStyle(.segmented)
                                    .frame(width: 170)
                                }

                                if viewModel.settings?.slideshowSource == .tag {
                                    artisanSettingsRow(title: "目标标签", subtitle: "从选定分类中挑选", showDivider: false) {
                                        Picker("", selection: Binding(
                                            get: { viewModel.settings?.slideshowTagId ?? "" },
                                            set: { setSlideshowTagId($0) }
                                        )) {
                                            if existingTags.isEmpty {
                                                Text("无标签").tag("")
                                            } else {
                                                ForEach(existingTags) { tag in
                                                    Text(tag.name).tag(tag.id.uuidString)
                                                }
                                            }
                                        }
                                        .frame(width: 150)
                                        .disabled(existingTags.isEmpty)
                                    }
                                }
                            }
                            .background(Color.black.opacity(0.1))
                        }
                    }
                }

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

    private func formatInterval(_ seconds: Double) -> String {
        let minutes = Int(seconds / 60)
        return minutes < 60 ? "\(minutes) 分钟" : "\(minutes / 60) 小时"
    }
}
