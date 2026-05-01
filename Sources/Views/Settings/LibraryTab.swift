import SwiftUI

struct LibraryTab: View {
    var viewModel: SettingsViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                artisanSettingsSection(header: "典藏资源库配置") {
                    artisanSettingsRow(title: "资源存储主路径", subtitle: viewModel.settings?.libraryPath ?? "~/Pictures/PlumLibrary") {
                        Button(action: { changeLibraryPath() }) {
                            Text("更改路径")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(LiquidGlassColors.primaryPink)
                                .padding(.horizontal, 14).padding(.vertical, 6)
                                .galleryCardStyle(radius: 8, padding: 0)
                        }
                        .buttonStyle(.plain)
                    }

                    artisanSettingsRow(title: "缓存空间管理", subtitle: "当前已占用 1.2 GB 缓存空间", showDivider: false) {
                        Button(action: { clearCache() }) {
                            Text("清理缓存")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(LiquidGlassColors.errorRed)
                                .padding(.horizontal, 14).padding(.vertical, 6)
                                .galleryCardStyle(radius: 8, padding: 0)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                // 存储提示
                VStack(alignment: .leading, spacing: 12) {
                    Label("存储建议", systemImage: "internaldrive.fill")
                        .font(.system(size: 11, weight: .black)).kerning(1).foregroundStyle(LiquidGlassColors.textQuaternary)
                    
                    Text("建议将资源库放置在固态硬盘 (SSD) 中，以获得最流畅的 4K/8K 视频预加载体验。")
                        .font(.system(size: 12)).foregroundStyle(LiquidGlassColors.textSecondary)
                        .lineSpacing(4)
                }
                .padding(24)
                .galleryCardStyle(radius: 20, padding: 0)
                .padding(.top, 20)
            }
            .padding(.top, 32)
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }
}
