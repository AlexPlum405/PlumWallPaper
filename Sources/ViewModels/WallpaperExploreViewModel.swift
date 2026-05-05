// Sources/ViewModels/WallpaperExploreViewModel.swift
import Foundation
import SwiftUI
import Combine

@MainActor
final class WallpaperExploreViewModel: ObservableObject {
    // MARK: - Published State
    @Published var wallpapers: [RemoteWallpaper] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasMore = true
    @Published var currentPage = 1

    // MARK: - Filters
    @Published var searchQuery = ""
    @Published var selectedSource: WallpaperSource = .wallhaven
    @Published var selectedCategory = "111"
    @Published var selectedPurity = "100"
    @Published var selectedSorting = "最新"
    @Published var selectedOrder = "desc"
    @Published var selectedTopRange: String? = nil
    @Published var selectedResolutionFilter = "全部"
    @Published var selectedResolutions: [String] = []
    @Published var selectedRatios: [String] = []
    @Published var selectedColors: [String] = []

    // MARK: - Services
    private let repository = WallpaperRepository.shared
    private let pexelsService = PexelsService.shared
    private let unsplashService = UnsplashService.shared
    private let pixabayService = PixabayService.shared
    private let bingDailyService = BingDailyService.shared
    private var loadGeneration = 0

    enum WallpaperSource: String, CaseIterable {
        case wallhaven = "Wallhaven"
        case bingDaily = "Bing 每日"
        case pexels = "Pexels"
        case unsplash = "Unsplash"
        case pixabay = "Pixabay"

        var displayName: String { rawValue }

        var requiresAPIKey: Bool {
            switch self {
            case .pexels, .unsplash, .pixabay: return true
            default: return false
            }
        }

        var apiKeyService: APIKeyManager.Service? {
            switch self {
            case .pexels: return .pexels
            case .unsplash: return .unsplash
            case .pixabay: return .pixabay
            default: return nil
            }
        }

        var supportsSearch: Bool {
            self != .bingDaily
        }

        var supportsPagination: Bool {
            true
        }
    }

    var showWallhavenFilters: Bool {
        selectedSource == .wallhaven
    }

    var sortingOptionsForCurrentSource: [String] {
        switch selectedSource {
        case .wallhaven:
            return ["最新", "热门", "随机", "最多浏览", "最多收藏"]
        case .pexels:
            return ["精选"]
        case .unsplash:
            return ["最新", "热门", "随机"]
        case .pixabay:
            return ["热门", "最新", "最多浏览", "最多收藏", "最多下载"]
        case .bingDaily:
            return ["最新"]
        }
    }

    var resolutionFilterOptions: [String] {
        switch selectedSource {
        case .wallhaven:
            return ["全部", "4K+", "2K+", "1080P+"]
        case .pexels, .unsplash, .pixabay:
            return ["全部", "大尺寸", "中等", "小尺寸"]
        case .bingDaily:
            return ["UHD"]
        }
    }

    var categoryFilterOptions: [(label: String, value: String)] {
        switch selectedSource {
        case .wallhaven:
            return [("全部", "111"), ("通用", "100"), ("动漫", "010"), ("人物", "001")]
        case .pexels:
            return [("全部", "全部"), ("自然", "nature wallpaper"), ("城市", "city wallpaper"), ("抽象", "abstract wallpaper"), ("科技", "technology wallpaper"), ("空间", "space wallpaper"), ("极简", "minimal wallpaper")]
        case .unsplash:
            return [("全部", "全部"), ("自然", "nature"), ("建筑", "architecture"), ("纹理", "textures"), ("暗色", "dark"), ("极简", "minimal"), ("桌面", "desktop")]
        case .pixabay:
            return [("全部", "全部"), ("自然", "nature wallpaper"), ("背景", "background"), ("抽象", "abstract"), ("动物", "animals"), ("科技", "technology"), ("空间", "space")]
        case .bingDaily:
            return [("全部", "全部")]
        }
    }

    func selectSource(_ source: WallpaperSource) {
        selectedSource = source
        let options = sortingOptionsForCurrentSource
        if !options.contains(selectedSorting) {
            selectedSorting = options.first ?? "最新"
        }
        selectedCategory = categoryFilterOptions.first?.value ?? "全部"
        if source != .wallhaven {
            selectedPurity = "100"
            selectedTopRange = nil
            selectedResolutionFilter = "全部"
            selectedResolutions = []
            selectedRatios = []
            selectedColors = []
        }
    }

    // MARK: - Public Methods

    func loadInitialData() async {
        loadGeneration += 1
        let generation = loadGeneration
        currentPage = 1
        wallpapers = []
        hasMore = true
        isLoading = false
        await loadMore(generation: generation)
    }

    func loadMore() async {
        await loadMore(generation: loadGeneration)
    }

    private func loadMore(generation: Int) async {
        guard !isLoading && hasMore else { return }
        isLoading = true
        errorMessage = nil
        defer {
            if generation == loadGeneration {
                isLoading = false
            }
        }

        do {
            let newWallpapers = try await fetchBySource()
            guard generation == loadGeneration else { return }
            let existingIds = Set(wallpapers.map(\.id))
            let uniqueNewWallpapers = newWallpapers.filter { !existingIds.contains($0.id) }

            if uniqueNewWallpapers.isEmpty {
                hasMore = false
            } else {
                wallpapers.append(contentsOf: uniqueNewWallpapers)
                currentPage += 1
                if !selectedSource.supportsPagination {
                    hasMore = false
                }
            }
        } catch {
            guard generation == loadGeneration else { return }
            errorMessage = "加载失败: \(error.localizedDescription)"
            print("[WallpaperExploreViewModel] Error: \(error)")
        }
    }

    func refresh() async {
        await loadInitialData()
    }

    func applyFilters() async {
        await loadInitialData()
    }

    // MARK: - Private

    private func fetchBySource() async throws -> [RemoteWallpaper] {
        switch selectedSource {
        case .wallhaven:
            return try await repository.search(
                query: searchQuery,
                page: currentPage,
                categories: selectedCategory,
                purity: selectedPurity,
                sorting: wallhavenSortingValue,
                order: selectedOrder,
                topRange: resolvedWallhavenTopRange,
                resolutions: selectedResolutions,
                ratios: selectedRatios,
                colors: selectedColors
            )
        case .bingDaily:
            let items = try await bingDailyService.fetchDaily(
                market: selectedBingMarket,
                page: currentPage,
                imageSize: selectedBingImageSize
            )
            return orderWallpapers(items, for: selectedSorting)
        case .pexels:
            return try await fetchPexelsPhotos()
        case .unsplash:
            return try await fetchUnsplashPhotos()
        case .pixabay:
            return try await fetchPixabayPhotos()
        }
    }

    private var wallhavenSortingValue: String {
        switch selectedSorting {
        case "热门":
            return "toplist"
        case "随机":
            return "random"
        case "最多浏览":
            return "views"
        case "最多收藏":
            return "favorites"
        default:
            return "date_added"
        }
    }

    private var resolvedWallhavenTopRange: String? {
        selectedSorting == "热门" ? "1M" : nil
    }

    private func fetchPexelsPhotos() async throws -> [RemoteWallpaper] {
        let trimmed = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        let items: [RemoteWallpaper]

        if trimmed.isEmpty {
            // 根据排序选择不同的数据源
            switch selectedSorting {
            case "最新":
                items = try await pexelsService.searchPhotos(query: resolvedStaticQuery(defaultQuery: "wallpaper nature"), page: currentPage, perPage: 20)
            case "随机":
                items = try await pexelsService.searchPhotos(query: resolvedStaticQuery(defaultQuery: "wallpaper"), page: currentPage, perPage: 20).shuffled()
            default: // "精选"
                if selectedCategory == "全部" {
                    items = try await pexelsService.fetchCurated(page: currentPage, perPage: 20)
                } else {
                    items = try await pexelsService.searchPhotos(query: selectedCategory, page: currentPage, perPage: 20)
                }
            }
        } else {
            items = try await pexelsService.searchPhotos(query: trimmed, page: currentPage, perPage: 20)
        }
        return orderWallpapers(applyClientFilters(items), for: selectedSorting)
    }

    private func fetchUnsplashPhotos() async throws -> [RemoteWallpaper] {
        let trimmed = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        let items: [RemoteWallpaper]

        if trimmed.isEmpty {
            switch selectedSorting {
            case "随机":
                items = try await unsplashService.fetchRandom(query: unsplashRandomQuery, count: 20)
            case "热门":
                if selectedCategory == "全部" {
                    items = try await unsplashService.fetchWallpaperTopic(
                        page: currentPage,
                        perPage: 20,
                        orderBy: "popular"
                    )
                } else {
                    items = try await unsplashService.searchPhotos(query: selectedCategory, page: currentPage, perPage: 20, orderBy: "popular")
                }
            default: // "最新"
                if selectedCategory == "全部" {
                    items = try await unsplashService.fetchWallpaperTopic(
                        page: currentPage,
                        perPage: 20,
                        orderBy: "latest"
                    )
                } else {
                    items = try await unsplashService.searchPhotos(query: selectedCategory, page: currentPage, perPage: 20, orderBy: "latest")
                }
            }
        } else {
            items = try await unsplashService.searchPhotos(query: trimmed, page: currentPage, perPage: 20)
        }
        return orderWallpapers(applyClientFilters(items), for: selectedSorting)
    }

    private func fetchPixabayPhotos() async throws -> [RemoteWallpaper] {
        let trimmed = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        let query = trimmed.isEmpty ? resolvedStaticQuery(defaultQuery: "wallpaper") : trimmed

        // 根据用户选择的分辨率动态调整 API 参数
        let (minWidth, minHeight) = pixabayMinResolution

        let items = try await pixabayService.searchPhotos(
            query: query,
            page: currentPage,
            perPage: 20,
            minWidth: minWidth,
            minHeight: minHeight,
            order: selectedSorting == "最新" ? "latest" : "popular"
        )
        return orderWallpapers(applyClientFilters(items), for: selectedSorting)
    }

    private func resolvedStaticQuery(defaultQuery: String) -> String {
        guard selectedCategory != "全部" else { return defaultQuery }
        return selectedCategory
    }

    private var unsplashRandomQuery: String? {
        selectedCategory == "全部" ? nil : selectedCategory
    }

    private var selectedBingMarket: String {
        selectedCategory == "全部" ? "zh-CN" : selectedCategory
    }

    private var selectedBingImageSize: String {
        let selected = activeResolutionFilter ?? "UHD"
        return selected == "全部" ? "UHD" : selected
    }

    private var pixabayMinResolution: (width: Int, height: Int) {
        guard let selectedResolution = activeResolutionFilter else {
            return (1920, 1080) // 默认 1080P
        }

        switch selectedResolution {
        case "4K+", "3840x2160", "UHD":
            return (3840, 2160)
        case "2K+", "2560x1440":
            return (2560, 1440)
        case "大尺寸":
            return (3000, 1800)
        case "中等":
            return (1920, 1080)
        case "小尺寸":
            return (1280, 720)
        default:
            return (1920, 1080)
        }
    }

    private func applyClientFilters(_ wallpapers: [RemoteWallpaper]) -> [RemoteWallpaper] {
        let filtered = wallpapers.filter { wallpaper in
            matchesResolution(wallpaper)
        }

        // 如果过滤后结果太少，记录警告
        if filtered.count < 3 && wallpapers.count > 10 {
            NSLog("[WallpaperExploreViewModel] 警告：分辨率过滤后仅剩 \(filtered.count)/\(wallpapers.count) 个结果（源：\(selectedSource.displayName)，分辨率：\(activeResolutionFilter ?? "全部")）")
        }

        return filtered
    }

    private func matchesResolution(_ wallpaper: RemoteWallpaper) -> Bool {
        guard let selectedResolution = activeResolutionFilter, selectedResolution != "全部" else {
            return true
        }

        let resolutionText = wallpaper.resolution.uppercased()
        switch selectedResolution {
        case "4K+", "3840x2160", "UHD":
            return wallpaper.dimensionX >= 3840 || wallpaper.dimensionY >= 2160 || resolutionText.contains("4K") || resolutionText.contains("3840")
        case "2K+", "2560x1440":
            return wallpaper.dimensionX >= 2560 || wallpaper.dimensionY >= 1440 || resolutionText.contains("2K") || resolutionText.contains("2560")
        case "1080P+", "1920x1080":
            return wallpaper.dimensionX >= 1920 || wallpaper.dimensionY >= 1080 || resolutionText.contains("1080") || resolutionText.contains("1920")
        case "大尺寸":
            return wallpaper.dimensionX >= 3000 || wallpaper.dimensionY >= 1800
        case "中等":
            return wallpaper.dimensionX >= 1920 && wallpaper.dimensionX < 3000
        case "小尺寸":
            return wallpaper.dimensionX < 1920
        default:
            return resolutionText.contains(selectedResolution.uppercased())
        }
    }

    private var activeResolutionFilter: String? {
        switch selectedSource {
        case .wallhaven:
            return selectedResolutions.first
        case .bingDaily:
            return selectedResolutionFilter == "全部" ? "UHD" : selectedResolutionFilter
        case .pexels, .unsplash, .pixabay:
            return selectedResolutionFilter == "全部" ? nil : selectedResolutionFilter
        }
    }

    private func orderWallpapers(_ wallpapers: [RemoteWallpaper], for sorting: String) -> [RemoteWallpaper] {
        switch sorting {
        case "随机":
            return wallpapers.shuffled()
        case "最多浏览":
            return wallpapers.sorted { $0.views > $1.views }
        case "最多收藏":
            return wallpapers.sorted { $0.favorites > $1.favorites }
        case "最多下载":
            return wallpapers.sorted { ($0.downloads ?? 0) > ($1.downloads ?? 0) }
        case "热门":
            return wallpapers.sorted {
                ($0.views + $0.favorites * 3 + ($0.downloads ?? 0)) > ($1.views + $1.favorites * 3 + ($1.downloads ?? 0))
            }
        case "最新":
            return wallpapers.sorted { $0.uploadedAt > $1.uploadedAt }
        case "最早":
            return wallpapers.sorted { $0.uploadedAt < $1.uploadedAt }
        default:
            return wallpapers
        }
    }
}
