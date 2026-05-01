import SwiftUI

extension WallpaperExploreView {
    func loadInitialData() {
        displayedWallpapers = createMockBatch(count: 12)
    }

    func loadMoreData() {
        guard !isLoadingMore && hasMoreData else { return }
        isLoadingMore = true

        // 模拟网络延迟
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            let newBatch = createMockBatch(count: 8)
            displayedWallpapers.append(contentsOf: newBatch)
            isLoadingMore = false

            // 模拟加载 4 次后到底
            if displayedWallpapers.count > 40 {
                hasMoreData = false
            }
        }
    }

    func refreshData() {
        displayedWallpapers = []
        hasMoreData = true
        loadInitialData()
    }

    func createMockBatch(count: Int) -> [Wallpaper] {
        let baseCount = displayedWallpapers.count
        return (0..<count).map { i in
            Wallpaper(
                id: UUID(),
                name: "壁纸资源 #\(baseCount + i + 1)",
                filePath: "https://mock.placeholder/wp\(baseCount + i).jpg",
                type: .image,
                resolution: "3840x2160",
                thumbnailPath: ""
            )
        }
    }
}
