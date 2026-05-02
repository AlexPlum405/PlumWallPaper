// Sources/ViewModels/HomeFeedViewModel.swift
import Foundation
import SwiftUI
import Combine

@MainActor
final class HomeFeedViewModel: ObservableObject {
    // MARK: - Published State
    @Published var heroItems: [MediaItem] = []
    @Published var latestStills: [RemoteWallpaper] = []
    @Published var popularMotions: [MediaItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Repositories
    private let wallpaperRepo = WallpaperRepository.shared
    private let mediaRepo = MediaRepository.shared

    // MARK: - Public Methods

    func loadInitialData() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil

        NSLog("[HomeFeedViewModel] 开始加载数据...")

        // 分别加载，避免一个失败导致全部失败
        do {
            NSLog("[HomeFeedViewModel] 加载 Hero 项目...")
            let hero = try await mediaRepo.fetchHeroItems()

            // 添加测试视频（有音轨）到 Hero 的第一个位置
            // 使用 Apple 官方示例视频
            let testVideoWithAudio = MediaItem(
                slug: "test-video-with-audio",
                title: "测试视频（带音频）- Apple Sample",
                pageURL: URL(string: "https://developer.apple.com/")!,
                thumbnailURL: URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.jpg")!,
                resolutionLabel: "1080p",
                collectionTitle: "音频测试",
                summary: "用于测试音频播放的视频",
                previewVideoURL: URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_adv_example_hevc/master.m3u8"),
                fullVideoURL: URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_adv_example_hevc/master.m3u8"),
                posterURL: URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.jpg"),
                tags: ["测试", "音频"],
                exactResolution: "1920x1080",
                durationSeconds: 30.0,
                downloadOptions: [],
                sourceName: "Apple 测试源",
                isAnimatedImage: false
            )

            // 将测试视频插入到第一个位置
            self.heroItems = [testVideoWithAudio] + hero
            NSLog("[HomeFeedViewModel] ✅ Hero: \(self.heroItems.count) 项（包含测试视频）")
        } catch {
            NSLog("[HomeFeedViewModel] ❌ Hero 加载失败: \(error)")
            NSLog("[HomeFeedViewModel] ❌ Hero 详细错误: \(String(describing: error))")
        }

        do {
            NSLog("[HomeFeedViewModel] 加载最新壁纸...")
            let latest = try await wallpaperRepo.fetchLatest()
            NSLog("[HomeFeedViewModel] ✅ Latest: \(latest.count) 项")
            self.latestStills = latest
        } catch {
            NSLog("[HomeFeedViewModel] ❌ Latest 加载失败: \(error)")
        }

        do {
            NSLog("[HomeFeedViewModel] 加载热门动态...")
            let popular = try await mediaRepo.fetchPopular()
            NSLog("[HomeFeedViewModel] ✅ Popular: \(popular.count) 项")
            self.popularMotions = popular
        } catch {
            NSLog("[HomeFeedViewModel] ❌ Popular 加载失败: \(error)")
            NSLog("[HomeFeedViewModel] ❌ Popular 详细错误: \(String(describing: error))")
        }

        isLoading = false
        NSLog("[HomeFeedViewModel] 加载完成")
    }

    func refresh() async {
        // 清除缓存以强制刷新
        wallpaperRepo.clearCache()
        mediaRepo.clearCache()
        await loadInitialData()
    }
}
