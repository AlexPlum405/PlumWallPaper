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
    @Published var isHeroLoading = false
    @Published var areShelvesLoading = false
    @Published var errorMessage: String?

    // MARK: - Repositories
    private let wallpaperRepo = WallpaperRepository.shared
    private let mediaRepo = MediaRepository.shared
    private var shelvesTask: Task<Void, Never>?

    var hasContent: Bool {
        !heroItems.isEmpty || !latestStills.isEmpty || !popularMotions.isEmpty
    }

    // MARK: - Public Methods

    func loadInitialData(force: Bool = false) async {
        guard force || !isLoading else { return }
        shelvesTask?.cancel()

        isLoading = true
        isHeroLoading = true
        areShelvesLoading = false
        errorMessage = nil

        NSLog("[HomeFeedViewModel] 开始加载数据...")

        do {
            NSLog("[HomeFeedViewModel] 加载 Hero 项目...")
            let hero = try await mediaRepo.fetchHeroItems()
            self.heroItems = hero
            NSLog("[HomeFeedViewModel] ✅ Hero: \(self.heroItems.count) 项")
            preheatHeroVideos()
        } catch {
            NSLog("[HomeFeedViewModel] ❌ Hero 加载失败: \(error)")
            self.errorMessage = "Hero 加载失败: \(error.localizedDescription)"
        }

        isHeroLoading = false
        isLoading = false
        NSLog("[HomeFeedViewModel] Hero 加载完成，开始后台加载 shelves")
        loadShelvesInBackground()
    }

    private func loadShelvesInBackground() {
        shelvesTask = Task { [weak self] in
            await self?.loadShelves()
        }
    }

    private func loadShelves() async {
        areShelvesLoading = true
        defer {
            areShelvesLoading = false
            NSLog("[HomeFeedViewModel] Shelves 加载完成")
        }

        async let latestResult = fetchLatestResult()
        async let popularResult = fetchPopularResult()
        let (latest, popular) = await (latestResult, popularResult)

        guard !Task.isCancelled else { return }

        switch latest {
        case .success(let latest):
            NSLog("[HomeFeedViewModel] ✅ Latest: \(latest.count) 项")
            latestStills = latest
        case .failure(let error):
            NSLog("[HomeFeedViewModel] ❌ Latest 加载失败: \(error)")
            if errorMessage == nil && !hasContent {
                errorMessage = "最新壁纸加载失败: \(error.localizedDescription)"
            }
        }

        switch popular {
        case .success(let popular):
            NSLog("[HomeFeedViewModel] ✅ Popular: \(popular.count) 项")
            popularMotions = popular
        case .failure(let error):
            NSLog("[HomeFeedViewModel] ❌ Popular 加载失败: \(error)")
            if errorMessage == nil && !hasContent {
                errorMessage = "热门动态加载失败: \(error.localizedDescription)"
            }
        }
    }

    private func fetchLatestResult() async -> Result<[RemoteWallpaper], Error> {
        do {
            NSLog("[HomeFeedViewModel] 加载最新壁纸...")
            return .success(try await wallpaperRepo.fetchLatest())
        } catch {
            return .failure(error)
        }
    }

    private func fetchPopularResult() async -> Result<[MediaItem], Error> {
        do {
            NSLog("[HomeFeedViewModel] 加载热门动态...")
            return .success(try await mediaRepo.fetchPopular())
        } catch {
            return .failure(error)
        }
    }

    private func preheatHeroVideos() {
        Task {
            for item in heroItems.prefix(3) {
                PreviewResourcePipeline.shared.preloadVideo(for: item, preferFullResolution: false, intent: .heroImmediate)
                try? await Task.sleep(nanoseconds: 200_000_000)
            }
        }
    }

    func refresh() async {
        // 清除缓存以强制刷新
        wallpaperRepo.clearCache()
        mediaRepo.clearCache()
        shelvesTask?.cancel()
        heroItems = []
        latestStills = []
        popularMotions = []
        await loadInitialData(force: true)
    }

    deinit {
        shelvesTask?.cancel()
    }
}
