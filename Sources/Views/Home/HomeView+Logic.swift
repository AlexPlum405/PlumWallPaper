import SwiftUI

extension HomeView {
    func showDetail(for index: Int, isDynamic: Bool) {
        let mock = createMockWallpaper(index: index, isDynamic: isDynamic)
        detailWallpaper = mock
    }

    func navigateDetail(direction: Int) {
        // 总共有 16 张 Mock 壁纸 (0-15)
        currentDetailIndex = (currentDetailIndex + direction + 16) % 16
        let isDynamic = currentDetailIndex >= 8
        detailWallpaper = createMockWallpaper(index: currentDetailIndex, isDynamic: isDynamic)
    }

    func createMockWallpaper(index: Int, isDynamic: Bool) -> Wallpaper {
        // 使用 heroItems 的图片或 Picsum 图片
        let imageURL = index < heroItems.count ? heroItems[index].imageURL : "https://picsum.photos/seed/\(index)/1920/1080"

        return Wallpaper(
            name: "壁纸 #\(index + 1)",
            filePath: imageURL, // 现在这里存的是 URL 字符串
            type: isDynamic ? .video : .image,
            resolution: isDynamic ? "3840 x 2160" : "5120 x 2880",
            fileSize: isDynamic ? Int64(890 * 1024 * 1024) : Int64(15 * 1024 * 1024),
            thumbnailPath: imageURL
        )
    }

    func nextHero() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            currentHeroIndex = (currentHeroIndex + 1) % heroItems.count
        }
    }
}
