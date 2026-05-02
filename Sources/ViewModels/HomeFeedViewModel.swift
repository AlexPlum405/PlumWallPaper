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
            self.heroItems = hero
            NSLog("[HomeFeedViewModel] ✅ Hero: \(self.heroItems.count) 项")
        } catch {
            NSLog("[HomeFeedViewModel] ❌ Hero 加载失败: \(error)")
            self.errorMessage = "Hero 加载失败: \(error.localizedDescription)"
        }

        do {
            NSLog("[HomeFeedViewModel] 加载最新壁纸...")
            let latest = try await wallpaperRepo.fetchLatest()
            NSLog("[HomeFeedViewModel] ✅ Latest: \(latest.count) 项")
            self.latestStills = latest
        } catch {
            NSLog("[HomeFeedViewModel] ❌ Latest 加载失败: \(error)")
            if self.errorMessage == nil {
                self.errorMessage = "最新壁纸加载失败: \(error.localizedDescription)"
            }
        }

        do {
            NSLog("[HomeFeedViewModel] 加载热门动态...")
            let popular = try await mediaRepo.fetchPopular()
            NSLog("[HomeFeedViewModel] ✅ Popular: \(popular.count) 项")
            self.popularMotions = popular
        } catch {
            NSLog("[HomeFeedViewModel] ❌ Popular 加载失败: \(error)")
            if self.errorMessage == nil {
                self.errorMessage = "热门动态加载失败: \(error.localizedDescription)"
            }
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
