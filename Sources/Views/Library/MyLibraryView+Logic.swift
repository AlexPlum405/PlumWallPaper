import SwiftUI

extension MyLibraryView {
    // 收藏状态枚举
    enum FavoriteState {
        case none    // 全部未收藏
        case partial // 部分收藏
        case all     // 全部已收藏
    }

    // 计算选中项的收藏状态
    var selectedFavoriteState: FavoriteState {
        let selected = viewModel.wallpapers.filter { selectedIDs.contains($0.id) }
        guard !selected.isEmpty else { return .none }

        let favoriteCount = selected.filter { $0.isFavorite }.count

        if favoriteCount == 0 {
            return .none
        } else if favoriteCount == selected.count {
            return .all
        } else {
            return .partial
        }
    }

    func toggleSelection(_ id: UUID) {
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
        } else {
            selectedIDs.insert(id)
        }
    }

    // 批量收藏/取消收藏（智能切换 + Toast 反馈）
    func performBatchFavorite() {
        let selected = viewModel.wallpapers.filter { selectedIDs.contains($0.id) }
        guard !selected.isEmpty else { return }

        let shouldFavorite = selectedFavoriteState != .all

        var changedCount = 0
        var skippedCount = 0

        for wallpaper in selected {
            if wallpaper.isFavorite == shouldFavorite {
                // 已经是目标状态，跳过
                skippedCount += 1
            } else {
                // 执行状态切换
                wallpaper.isFavorite = shouldFavorite
                changedCount += 1
            }
        }

        viewModel.save()

        // 生成 Toast 消息
        let message = generateFavoriteToastMessage(
            changed: changedCount,
            skipped: skippedCount,
            isFavorite: shouldFavorite
        )

        toast = ToastConfig(message: message, type: .success)

        // 操作完成后自动退出编辑模式
        exitEditMode()
    }

    // 生成收藏操作的 Toast 消息
    func generateFavoriteToastMessage(changed: Int, skipped: Int, isFavorite: Bool) -> String {
        let action = isFavorite ? "收藏" : "取消收藏"

        if skipped == 0 {
            // 全部操作成功
            return "已\(action) \(changed) 项"
        } else {
            // 部分跳过
            let skipReason = isFavorite ? "已收藏" : "未收藏"
            return "已\(action) \(changed) 项，\(skipped) 项\(skipReason)"
        }
    }

    // 批量删除（带二次确认）
    func performBatchDelete() {
        showDeleteConfirm = true
    }

    func confirmDelete() {
        let deleteCount = selectedIDs.count

        // 执行删除
        viewModel.wallpapers.removeAll { selectedIDs.contains($0.id) }
        viewModel.save()

        toast = ToastConfig(message: "已删除 \(deleteCount) 项", type: .success)

        // 操作完成后自动退出编辑模式
        exitEditMode()
    }

    // 退出编辑模式
    func exitEditMode() {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
            isEditMode = false
            selectedIDs.removeAll()
        }
    }

    // MARK: - 筛选逻辑

    var filteredWallpapers: [Wallpaper] {
        switch viewModel.selectedTab {
        case .favorites: return viewModel.wallpapers.filter { $0.isFavorite }
        case .downloads: return viewModel.wallpapers
        case .history: return Array(viewModel.wallpapers.prefix(3))
        }
    }
}
