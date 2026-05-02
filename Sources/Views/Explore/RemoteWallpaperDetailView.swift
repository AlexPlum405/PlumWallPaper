import SwiftUI

// MARK: - Remote Wallpaper Detail View
struct RemoteWallpaperDetailView: View {
    let wallpaper: RemoteWallpaper
    @Environment(\.dismiss) private var dismiss
    @State private var isDownloading = false

    var body: some View {
        ZStack {
            LiquidGlassColors.deepBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    // 关闭按钮
                    HStack {
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(LiquidGlassColors.textSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 20)

                    // 壁纸预览
                    wallpaperPreview

                    // 信息和操作
                    infoSection

                    // 标签
                    if let tags = wallpaper.tags, !tags.isEmpty {
                        tagsSection(tags: tags)
                    }
                }
                .padding(.bottom, 60)
            }
        }
    }

    // MARK: - 壁纸预览
    private var wallpaperPreview: some View {
        Group {
            if let fullImageURL = wallpaper.fullImageURL {
                AsyncImage(url: fullImageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    case .failure:
                        placeholderView
                    case .empty:
                        ProgressView()
                            .controlSize(.large)
                            .tint(LiquidGlassColors.primaryPink)
                    @unknown default:
                        placeholderView
                    }
                }
            } else {
                placeholderView
            }
        }
        .frame(maxWidth: 800)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.3), radius: 40, x: 0, y: 20)
        .padding(.horizontal, 40)
    }

    private var placeholderView: some View {
        Rectangle()
            .fill(LiquidGlassColors.surfaceBackground)
            .aspectRatio(16/9, contentMode: .fit)
            .overlay {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 64))
                    .foregroundStyle(LiquidGlassColors.textQuaternary)
            }
    }

    // MARK: - 信息区域
    private var infoSection: some View {
        VStack(spacing: 24) {
            // 标题和统计
            VStack(spacing: 12) {
                Text(wallpaper.tags?.first?.name ?? "Wallpaper")
                    .font(.custom("Georgia", size: 32).bold())
                    .foregroundStyle(LiquidGlassColors.textPrimary)

                HStack(spacing: 24) {
                    statItem(icon: "eye", value: formatNumber(wallpaper.views), label: "浏览")
                    statItem(icon: "heart", value: formatNumber(wallpaper.favorites), label: "收藏")
                    statItem(icon: "square.resize", value: wallpaper.resolution, label: "分辨率")
                }
            }

            // 操作按钮
            HStack(spacing: 16) {
                Button {
                    if let url = URL(string: wallpaper.url) {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    Label("在浏览器中打开", systemImage: "safari")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .frame(height: 44)
                        .background(LiquidGlassColors.primaryPink)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Button {
                    // TODO: 实现下载功能
                    isDownloading = true
                } label: {
                    Label("下载", systemImage: "arrow.down.circle")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(LiquidGlassColors.textPrimary)
                        .padding(.horizontal, 24)
                        .frame(height: 44)
                        .background(LiquidGlassColors.surfaceBackground)
                        .clipShape(Capsule())
                        .overlay {
                            Capsule().stroke(LiquidGlassColors.glassBorder, lineWidth: 0.5)
                        }
                }
                .buttonStyle(.plain)
                .disabled(isDownloading)
            }
        }
        .padding(.horizontal, 40)
    }

    // MARK: - 标签区域
    private func tagsSection(tags: [APITag]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("标签")
                .font(.system(size: 13, weight: .black))
                .kerning(1.5)
                .foregroundStyle(LiquidGlassColors.textQuaternary)

            FlowLayout(spacing: 8) {
                ForEach(tags, id: \.id) { tag in
                    Text(tag.name)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(LiquidGlassColors.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(LiquidGlassColors.surfaceBackground.opacity(0.6))
                        .clipShape(Capsule())
                        .overlay {
                            Capsule().stroke(LiquidGlassColors.glassBorder, lineWidth: 0.5)
                        }
                }
            }
        }
        .frame(maxWidth: 800)
        .padding(.horizontal, 40)
    }

    // MARK: - 辅助函数
    private func statItem(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(value)
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundStyle(LiquidGlassColors.textPrimary)

            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(LiquidGlassColors.textSecondary)
        }
    }

    private func formatNumber(_ number: Int) -> String {
        if number >= 1_000_000 {
            return String(format: "%.1fM", Double(number) / 1_000_000.0)
        } else if number >= 1000 {
            return String(format: "%.1fk", Double(number) / 1000.0)
        }
        return "\(number)"
    }
}
