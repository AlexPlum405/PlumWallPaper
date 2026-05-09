import SwiftUI

struct DetailActionDock: View {
    let isFavorite: Bool
    let isApplying: Bool
    let isDownloading: Bool
    let onFavorite: () -> Void
    let onApply: () -> Void
    let onDownload: () -> Void

    var body: some View {
        PlumHUDSurface(cornerRadius: 36, padding: 8) {
            HStack(spacing: 12) {
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
}
