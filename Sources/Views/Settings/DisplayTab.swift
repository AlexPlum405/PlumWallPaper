import SwiftUI

struct DisplayTab: View {
    var viewModel: SettingsViewModel
    
    // 模拟屏幕顺序列表
    @State private var mockScreens = ["Studio Display (Main)", "Side Monitor", "Liquid Retina XDR"]

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                artisanSettingsSection(header: "空间几何与色彩") {
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

                // 屏幕顺序排序
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
            }
            .padding(.top, 32)
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }
}
