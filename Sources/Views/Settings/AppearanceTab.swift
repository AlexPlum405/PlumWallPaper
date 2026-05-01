import SwiftUI

struct AppearanceTab: View {
    var viewModel: SettingsViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                artisanSettingsSection(header: "视觉语言与氛围") {
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
                
                // 品牌展示
                VStack(spacing: 16) {
                    Image(nsImage: NSApp.applicationIconImage ?? NSImage())
                        .resizable()
                        .frame(width: 64, height: 64)
                        .artisanShadow(radius: 20)
                    
                    VStack(spacing: 4) {
                        Text("Plum Artisan Edition")
                            .font(.custom("Georgia", size: 16).bold().italic())
                            .foregroundStyle(LiquidGlassColors.primaryPink)
                        Text("Crafted for Digital Art Curators").font(.system(size: 10, weight: .black)).kerning(1).foregroundStyle(LiquidGlassColors.textQuaternary)
                    }
                }.padding(.top, 40)
            }
            .padding(.top, 32)
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }
}
