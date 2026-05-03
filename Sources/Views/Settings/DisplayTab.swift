import SwiftUI

struct DisplayTab: View {
    var viewModel: SettingsViewModel
    
    // 模拟屏幕顺序列表
    @State private var mockScreens = ["Studio Display (Main)", "Side Monitor", "Liquid Retina XDR"]

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // MARK: - [空间几何与色彩]
                artisanSettingsSection(header: "空间几何与色彩 (SPACE & COLOR)") {
                    artisanSettingsRow(title: "多屏渲染拓扑", subtitle: "定义多个显示器之间的逻辑关联") {
                        Picker("", selection: Binding(
                            get: { viewModel.settings?.displayTopology ?? .independent },
                            set: { setDisplayTopology($0) }
                        )) {
                            Text("独立").tag(DisplayTopology.independent)
                            Text("镜像").tag(DisplayTopology.mirror)
                            Text("全景").tag(DisplayTopology.panorama)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 180)
                    }

                    artisanSettingsRow(title: "色彩空间规范", subtitle: "匹配显示器硬件的色彩表现能力") {
                        Picker("", selection: Binding(
                            get: { viewModel.settings?.colorSpace ?? .srgb },
                            set: { setColorSpace($0) }
                        )) {
                            Text("sRGB").tag(ColorSpaceOption.srgb)
                            Text("P3").tag(ColorSpaceOption.p3)
                            Text("2020").tag(ColorSpaceOption.adobeRGB)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 180)
                    }
                }

                // MARK: - [物理排布顺序]
                VStack(alignment: .leading, spacing: 16) {
                    LiquidGlassSectionHeader(title: "物理排布顺序", icon: "arrow.left.and.right.square", color: LiquidGlassColors.primaryPink)
                    
                    VStack(spacing: 12) {
                        ForEach(mockScreens, id: \.self) { screen in
                            HStack {
                                Image(systemName: "line.3.horizontal")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(LiquidGlassColors.textQuaternary)
                                
                                Image(systemName: "display")
                                    .font(.system(size: 14))
                                    .foregroundStyle(LiquidGlassColors.primaryPink)
                                
                                Text(screen)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(LiquidGlassColors.textPrimary)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 44)
                            .galleryCardStyle(radius: 12, padding: 0)
                        }
                    }
                    
                    Text("拖拽行以调整全景模式下的渲染衔接顺序。")
                        .font(.system(size: 11))
                        .foregroundStyle(LiquidGlassColors.textQuaternary)
                        .padding(.leading, 4)
                }

                // MARK: - [视觉语言与氛围]
                artisanSettingsSection(header: "视觉语言与氛围 (ATMOSPHERE)") {
                    artisanSettingsRow(title: "画廊底色模式", subtitle: "设置应用程序的主题外观层级") {
                        Picker("", selection: Binding(
                            get: { viewModel.settings?.themeMode ?? .auto },
                            set: { setThemeMode($0) }
                        )) {
                            Text("自动").tag(ThemeMode.auto)
                            Text("浅色").tag(ThemeMode.light)
                            Text("深色").tag(ThemeMode.dark)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 180)
                    }

                    artisanSettingsRow(title: "缩略图精细度", subtitle: "决定本地与精选页的预览图显示比例") {
                        Picker("", selection: Binding(
                            get: { viewModel.settings?.thumbnailSize ?? .medium },
                            set: { setThumbnailSize($0) }
                        )) {
                            Text("紧凑").tag(ThumbnailSize.small)
                            Text("平衡").tag(ThumbnailSize.medium)
                            Text("精美").tag(ThumbnailSize.large)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 180)
                    }

                    artisanSettingsRow(title: "全局动态特效", subtitle: "启用界面间的丝滑过渡与液态动画效果", showDivider: false) {
                        artisanToggle(isOn: Binding(
                            get: { viewModel.settings?.animationsEnabled ?? true },
                            set: { setAnimationsEnabled($0) }
                        ))
                    }
                }

                // MARK: - [艺术呈现参数]
                artisanSettingsSection(header: "艺术呈现参数 (ARTISTIC RENDERING)") {
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
                }
            }
            .padding(.top, 32)
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }
}
