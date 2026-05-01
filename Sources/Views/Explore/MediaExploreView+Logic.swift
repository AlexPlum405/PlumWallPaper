import SwiftUI

extension MediaExploreView {
    // MARK: - 逻辑

    func loadInitialData() {
        displayedMedia = createMockBatch(count: 10)
    }

    func loadMoreData() {
        guard !isLoadingMore && hasMoreData else { return }
        isLoadingMore = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            let newBatch = createMockBatch(count: 6)
            displayedMedia.append(contentsOf: newBatch)
            isLoadingMore = false

            if displayedMedia.count > 30 {
                hasMoreData = false
            }
        }
    }

    func createMockBatch(count: Int) -> [Wallpaper] {
        let baseCount = displayedMedia.count
        return (0..<count).map { i in
            Wallpaper(
                id: UUID(),
                name: "引擎资源 #\(baseCount + i + 1)",
                filePath: "https://mock.placeholder/media\(baseCount + i).jpg",
                type: .video,
                resolution: "4K · 60FPS",
                duration: Double.random(in: 15...120), // 随机时长
                thumbnailPath: ""
            )
        }
    }
}
