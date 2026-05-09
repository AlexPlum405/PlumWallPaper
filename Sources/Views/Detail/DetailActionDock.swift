import SwiftUI

struct DetailActionDock: View {
    let isFavorite: Bool
    let isApplying: Bool
    let isStudioActive: Bool
    let isCleanPreviewActive: Bool
    let isDownloading: Bool
    let onPreviewMode: () -> Void
    let onStudioMode: () -> Void
    let onCleanPreviewMode: () -> Void
    let onFavorite: () -> Void
    let onApply: () -> Void
    let onDownload: () -> Void

    var body: some View {
        PlumHUDSurface(cornerRadius: 34, padding: 10) {
            HStack(spacing: 14) {
                modeSwitcher

                Rectangle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 0.5, height: 34)
                    .padding(.horizontal, 2)

                PlumIconActionButton(
                    icon: isFavorite ? "heart.fill" : "heart",
                    title: "收藏",
                    isActive: isFavorite,
                    help: isFavorite ? "取消收藏" : "收藏",
                    action: onFavorite
                )

                PlumPrimaryActionButton(
                    title: isApplying ? "正在应用" : "设为壁纸",
                    icon: "macwindow.on.rectangle",
                    isBusy: isApplying,
                    action: onApply
                )

                PlumIconActionButton(
                    icon: "arrow.down.to.line.compact",
                    title: isDownloading ? "下载中" : "下载",
                    isBusy: isDownloading,
                    help: "下载原片",
                    action: onDownload
                )
            }
        }
    }

    private var modeSwitcher: some View {
        HStack(spacing: 4) {
            modeButton(
                title: "预览",
                icon: "eye",
                isSelected: !isStudioActive && !isCleanPreviewActive,
                action: onPreviewMode
            )

            modeButton(
                title: "调校",
                icon: "camera.aperture",
                isSelected: isStudioActive && !isCleanPreviewActive,
                action: onStudioMode
            )

            modeButton(
                title: "纯净",
                icon: "rectangle.inset.filled",
                isSelected: isCleanPreviewActive,
                action: onCleanPreviewMode
            )
        }
        .padding(4)
        .background(Capsule(style: .continuous).fill(Color.white.opacity(0.045)))
        .overlay(Capsule(style: .continuous).stroke(Color.white.opacity(0.08), lineWidth: 0.5))
    }

    private func modeButton(title: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
                Text(title)
                    .font(.system(size: 11, weight: .bold))
            }
            .foregroundStyle(isSelected ? .black.opacity(0.84) : LiquidGlassColors.textSecondary)
            .padding(.horizontal, 13)
            .frame(height: 40)
            .background {
                if isSelected {
                    Capsule(style: .continuous)
                        .fill(LiquidGlassColors.primaryPink)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
