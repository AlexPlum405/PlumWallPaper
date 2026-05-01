import SwiftUI

struct SlideshowTab: View {
    var viewModel: SettingsViewModel
    
    // 模拟标签列表
    private let mockTags = ["全量作品", "收藏精选", "4K UHD", "视觉诗篇", "极简空间"]

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                artisanSettingsSection(header: "自动轮播策略") {
                    artisanSettingsRow(title: "启用轮播", subtitle: "定时自动切换桌面艺术作品") {
                        artisanToggle(isOn: Binding(
                            get: { viewModel.settings?.slideshowEnabled ?? false },
                            set: { setSlideshowEnabled($0) }
                        ))
                    }

                    if viewModel.settings?.slideshowEnabled ?? false {
                        artisanSettingsRow(title: "轮播间隔", subtitle: "设置作品自动切换的时间跨度") {
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
                                .frame(width: 120)
                            }
                        }

                        artisanSettingsRow(title: "轮播顺序", subtitle: "决定下一次出现的作品逻辑") {
                            Picker("", selection: Binding(
                                get: { viewModel.settings?.slideshowOrder ?? .random },
                                set: { setSlideshowOrder($0) }
                            )) {
                                Text("顺序").tag(SlideshowOrder.sequential)
                                Text("随机").tag(SlideshowOrder.random)
                                Text("洗牌").tag(SlideshowOrder.favoritesFirst)
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 180)
                        }

                        artisanSettingsRow(title: "资源来源", subtitle: "限定参与轮播的作品范围") {
                            Picker("", selection: Binding(
                                get: { viewModel.settings?.slideshowSource ?? .all },
                                set: { setSlideshowSource($0) }
                            )) {
                                Text("全部").tag(SlideshowSource.all)
                                Text("收藏").tag(SlideshowSource.favorites)
                                Text("标签").tag(SlideshowSource.tag)
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 180)
                        }

                        if viewModel.settings?.slideshowSource == .tag {
                            artisanSettingsRow(title: "选择目标标签", subtitle: "仅从选定分类中挑选作品", showDivider: false) {
                                Picker("", selection: Binding(
                                    get: { viewModel.settings?.slideshowTagId ?? "" },
                                    set: { setSlideshowTagId($0) }
                                )) {
                                    ForEach(mockTags, id: \.self) { tag in
                                        Text(tag).tag(tag)
                                    }
                                }
                                .frame(width: 160)
                            }
                        }
                    }
                }
            }
            .padding(.top, 32)
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
        .animation(.gallerySpring, value: viewModel.settings?.slideshowEnabled)
        .animation(.gallerySpring, value: viewModel.settings?.slideshowSource)
    }
    
    private func formatInterval(_ seconds: Double) -> String {
        let minutes = Int(seconds / 60)
        if minutes < 60 {
            return "\(minutes) 分钟"
        } else {
            let hours = minutes / 60
            return "\(hours) 小时"
        }
    }
}
