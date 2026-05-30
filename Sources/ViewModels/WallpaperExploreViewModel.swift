// Sources/ViewModels/WallpaperExploreViewModel.swift
import Foundation
import SwiftUI
import Combine

@MainActor
final class WallpaperExploreViewModel: ObservableObject {
    struct SourceCapability: Equatable {
        let supportsSearch: Bool
        let supportsPagination: Bool
        let supportsCategory: Bool
        let supportsSorting: Bool
        let supportsResolution: Bool
        let supportsExactResolution: Bool
        let supportsRatio: Bool
        let supportsColor: Bool
        let supportsPurity: Bool
        let apiKeyService: APIKeyManager.Service?
        let note: String

        var requiresAPIKey: Bool { apiKeyService != nil }
    }

    struct ActiveFilter: Identifiable, Equatable {
        let id: String
        let label: String
        let icon: String
    }

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
            capability.requiresAPIKey
        }

        var apiKeyService: APIKeyManager.Service? {
            capability.apiKeyService
        }

        var supportsSearch: Bool {
            capability.supportsSearch
        }

        var supportsPagination: Bool {
            capability.supportsPagination
        }

        var capability: SourceCapability {
            switch self {
            case .wallhaven:
                return SourceCapability(
                    supportsSearch: true,
                    supportsPagination: true,
                    supportsCategory: true,
                    supportsSorting: true,
                    supportsResolution: true,
                    supportsExactResolution: true,
                    supportsRatio: true,
                    supportsColor: true,
                    supportsPurity: true,
                    apiKeyService: nil,
                    note: "支持关键词、分类、纯度、排序、精确分辨率、比例和颜色筛选"
                )
            case .bingDaily:
                return SourceCapability(
                    supportsSearch: false,
                    supportsPagination: true,
                    supportsCategory: true,
                    supportsSorting: false,
                    supportsResolution: true,
                    supportsExactResolution: false,
                    supportsRatio: false,
                    supportsColor: false,
                    supportsPurity: false,
                    apiKeyService: nil,
                    note: "按市场浏览 Bing 每日壁纸，可选择图片尺寸"
                )
            case .pexels:
                return SourceCapability(
                    supportsSearch: true,
                    supportsPagination: true,
                    supportsCategory: true,
                    supportsSorting: false,
                    supportsResolution: true,
                    supportsExactResolution: false,
                    supportsRatio: false,
                    supportsColor: false,
                    supportsPurity: false,
                    apiKeyService: .pexels,
                    note: "支持关键词和主题分类，分辨率在本地做轻量过滤"
                )
            case .unsplash:
                return SourceCapability(
                    supportsSearch: true,
                    supportsPagination: true,
                    supportsCategory: true,
                    supportsSorting: true,
                    supportsResolution: true,
                    supportsExactResolution: false,
                    supportsRatio: false,
                    supportsColor: false,
                    supportsPurity: false,
                    apiKeyService: .unsplash,
                    note: "支持关键词、主题、排序和本地分辨率过滤"
                )
            case .pixabay:
                return SourceCapability(
                    supportsSearch: true,
                    supportsPagination: true,
                    supportsCategory: true,
                    supportsSorting: true,
                    supportsResolution: true,
                    supportsExactResolution: false,
                    supportsRatio: false,
                    supportsColor: false,
                    supportsPurity: false,
                    apiKeyService: .pixabay,
                    note: "支持关键词、分类、排序和最小尺寸筛选"
                )
            }
        }
    }

    var currentCapabilities: SourceCapability {
        selectedSource.capability
    }

    var sourceCapabilitySummary: String {
        var features: [String] = []
        if currentCapabilities.supportsSearch { features.append("搜索") }
        if currentCapabilities.supportsPagination { features.append("分页") }
        if currentCapabilities.supportsCategory { features.append("分类") }
        if currentCapabilities.supportsSorting { features.append("排序") }
        if currentCapabilities.supportsResolution { features.append("分辨率") }
        if currentCapabilities.supportsRatio { features.append("比例") }
        if currentCapabilities.supportsColor { features.append("颜色") }
        if currentCapabilities.supportsPurity { features.append("纯度") }

        let apiStatus: String
        if let service = currentCapabilities.apiKeyService {
            apiStatus = APIKeyManager.shared.hasKey(for: service) ? "API Key 已配置" : "需要 API Key"
        } else {
            apiStatus = "无需 API Key"
        }

        return "\(selectedSource.displayName) · \(features.joined(separator: " / ")) · \(apiStatus)"
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
            return ["UHD", "1920x1080", "1366x768"]
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
            return [("中国", "zh-CN"), ("美国", "en-US"), ("日本", "ja-JP"), ("英国", "en-GB"), ("德国", "de-DE")]
        }
    }

    var activeFilters: [ActiveFilter] {
        var filters: [ActiveFilter] = []
        let trimmedSearch = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if currentCapabilities.supportsSearch && !trimmedSearch.isEmpty {
            filters.append(ActiveFilter(id: "search", label: "搜索: \(trimmedSearch)", icon: "magnifyingglass"))
        }

        if currentCapabilities.supportsCategory,
           selectedCategory != defaultCategoryValue,
           let label = categoryFilterOptions.first(where: { $0.value == selectedCategory })?.label {
            filters.append(ActiveFilter(id: "category", label: "分类: \(label)", icon: "folder"))
        }

        if currentCapabilities.supportsPurity,
           selectedPurity != defaultPurityValue,
           let label = purityLabel(for: selectedPurity) {
            filters.append(ActiveFilter(id: "purity", label: "纯度: \(label)", icon: "shield"))
        }

        if currentCapabilities.supportsSorting,
           selectedSorting != defaultSortingValue {
            filters.append(ActiveFilter(id: "sorting", label: "排序: \(selectedSorting)", icon: "arrow.up.arrow.down"))
        }

        if currentCapabilities.supportsExactResolution {
            for resolution in selectedResolutions {
                filters.append(ActiveFilter(id: "resolution:\(resolution)", label: "分辨率: \(resolution)", icon: "rectangle.expand.vertical"))
            }
        } else if currentCapabilities.supportsResolution,
                  selectedResolutionFilter != defaultResolutionValue {
            filters.append(ActiveFilter(id: "resolution-filter", label: "分辨率: \(selectedResolutionFilter)", icon: "rectangle.expand.vertical"))
        }

        if currentCapabilities.supportsRatio {
            for ratio in selectedRatios {
                filters.append(ActiveFilter(id: "ratio:\(ratio)", label: "比例: \(ratioLabel(for: ratio))", icon: "aspectratio"))
            }
        }

        if currentCapabilities.supportsColor {
            for color in selectedColors {
                filters.append(ActiveFilter(id: "color:\(color)", label: "颜色: \(colorLabel(for: color))", icon: "paintpalette"))
            }
        }

        return filters
    }

    func selectSource(_ source: WallpaperSource) {
        selectedSource = source
        normalizeFiltersForCurrentSource()
    }

    func resetFiltersForCurrentSource() {
        searchQuery = ""
        selectedCategory = defaultCategoryValue
        selectedPurity = defaultPurityValue
        selectedSorting = defaultSortingValue
        selectedOrder = "desc"
        selectedTopRange = nil
        selectedResolutionFilter = defaultResolutionValue
        selectedResolutions = []
        selectedRatios = []
        selectedColors = []
        normalizeFiltersForCurrentSource()
    }

    func clearActiveFilter(_ id: String) {
        if id == "search" {
            searchQuery = ""
        } else if id == "category" {
            selectedCategory = defaultCategoryValue
        } else if id == "purity" {
            selectedPurity = defaultPurityValue
        } else if id == "sorting" {
            selectedSorting = defaultSortingValue
        } else if id == "resolution-filter" {
            selectedResolutionFilter = defaultResolutionValue
        } else if id.hasPrefix("resolution:") {
            let value = String(id.dropFirst("resolution:".count))
            selectedResolutions.removeAll { $0 == value }
        } else if id.hasPrefix("ratio:") {
            let value = String(id.dropFirst("ratio:".count))
            selectedRatios.removeAll { $0 == value }
        } else if id.hasPrefix("color:") {
            let value = String(id.dropFirst("color:".count))
            selectedColors.removeAll { $0 == value }
        }
        normalizeFiltersForCurrentSource()
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
        normalizeFiltersForCurrentSource()
        await loadInitialData()
    }

    // MARK: - Private

    private var defaultCategoryValue: String {
        categoryFilterOptions.first?.value ?? "全部"
    }

    private var defaultSortingValue: String {
        sortingOptionsForCurrentSource.first ?? "最新"
    }

    private var defaultResolutionValue: String {
        resolutionFilterOptions.first ?? "全部"
    }

    private var defaultPurityValue: String {
        "100"
    }

    private func normalizeFiltersForCurrentSource() {
        let capabilities = currentCapabilities

        if !capabilities.supportsSearch {
            searchQuery = ""
        }

        let categoryValues = Set(categoryFilterOptions.map(\.value))
        if !capabilities.supportsCategory || !categoryValues.contains(selectedCategory) {
            selectedCategory = defaultCategoryValue
        }

        let sortingOptions = sortingOptionsForCurrentSource
        if !sortingOptions.contains(selectedSorting) {
            selectedSorting = defaultSortingValue
        }

        if !capabilities.supportsPurity {
            selectedPurity = defaultPurityValue
        }

        if !capabilities.supportsExactResolution {
            selectedResolutions = []
        }

        if !capabilities.supportsResolution || !resolutionFilterOptions.contains(selectedResolutionFilter) {
            selectedResolutionFilter = defaultResolutionValue
        }

        if !capabilities.supportsRatio {
            selectedRatios = []
        } else {
            let validRatios = Set(Self.ratioOptions.map(\.value))
            selectedRatios = selectedRatios.filter { validRatios.contains($0) }
        }

        if !capabilities.supportsColor {
            selectedColors = []
        } else {
            let validColors = Set(Self.colorOptions.map(\.value))
            selectedColors = selectedColors.filter { validColors.contains($0) }
        }

        if selectedSource != .wallhaven {
            selectedTopRange = nil
        }
    }

    private func purityLabel(for value: String) -> String? {
        Self.purityOptions.first { $0.value == value }?.label
    }

    private func ratioLabel(for value: String) -> String {
        Self.ratioOptions.first { $0.value == value }?.label ?? value
    }

    private func colorLabel(for value: String) -> String {
        Self.colorOptions.first { $0.value == value }?.label ?? value
    }

    private static let purityOptions: [(label: String, value: String)] = [
        ("SFW", "100"),
        ("Sketchy", "010")
    ]

    private static let ratioOptions: [(label: String, value: String)] = [
        ("16:9", "16x9"),
        ("16:10", "16x10"),
        ("21:9", "21x9"),
        ("32:9", "32x9"),
        ("9:16", "9x16")
    ]

    private static let colorOptions: [(label: String, value: String)] = [
        ("红", "660000"),
        ("橙", "cc6600"),
        ("黄", "ffcc00"),
        ("绿", "009900"),
        ("青", "00cccc"),
        ("蓝", "0066cc"),
        ("紫", "9900cc"),
        ("粉", "ff66cc"),
        ("黑", "000000"),
        ("白", "ffffff"),
        ("灰", "999999"),
        ("棕", "996633")
    ]

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
