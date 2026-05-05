// Sources/ViewModels/MediaExploreViewModel.swift
import Foundation
import SwiftUI
import Combine
import AVFoundation

@MainActor
final class MediaExploreViewModel: ObservableObject {
    // MARK: - Published State
    @Published var mediaItems: [MediaItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasMore = true
    @Published var currentPage = 1

    // MARK: - Filters
    @Published var searchQuery = ""
    @Published var selectedSource: MediaSource = .motionBG
    @Published var selectedCategory = "全部"
    @Published var selectedResolution: String? = nil
    @Published var selectedSorting = "最新"
    @Published var selectedDuration = "全部"

    // MARK: - Repository
    private let repository = MediaRepository.shared
    private let mediaService = MediaService.shared
    private let workshopService = WorkshopService.shared
    private let pexelsService = PexelsService.shared
    private let pixabayService = PixabayService.shared
    private let desktopHutService = DesktopHutService.shared
    private var loadGeneration = 0

    enum MediaSource: String, CaseIterable {
        case motionBG = "MotionBG"
        case workshop = "Steam Workshop"
        case pexelsVideo = "Pexels"
        case pixabayVideo = "Pixabay"
        case desktopHut = "DesktopHut"

        var displayName: String { rawValue }

        var isAvailable: Bool {
            switch self {
            case .workshop: return false  // 即将推出
            default: return true
            }
        }

        var requiresAPIKey: Bool {
            switch self {
            case .pexelsVideo, .pixabayVideo: return true
            default: return false
            }
        }

        var apiKeyService: APIKeyManager.Service? {
            switch self {
            case .pexelsVideo: return .pexels
            case .pixabayVideo: return .pixabay
            default: return nil
            }
        }
    }

    enum AudioTrackFilter: String, CaseIterable {
        case all = "全部"
        case withAudio = "有声音"

        var displayName: String { rawValue }
    }

    var sortingOptionsForCurrentSource: [String] {
        switch selectedSource {
        case .motionBG:
            return ["最新"]
        case .workshop:
            return ["热门", "最新", "最高评分", "最多订阅"]
        case .pexelsVideo:
            return ["热门"]
        case .pixabayVideo:
            return ["热门", "最新"]
        case .desktopHut:
            return ["最新", "随机", "高分辨率优先"]
        }
    }

    var resolutionFilterOptions: [String] {
        switch selectedSource {
        case .motionBG:
            return ["全部"]
        case .desktopHut:
            return ["全部", "4096x2304", "3840x2160", "1920x1080", "2048x1152"]
        case .workshop:
            return ["全部", "3840x2160", "2560x1440", "1920x1080", "1280x720"]
        case .pexelsVideo, .pixabayVideo:
            return ["全部", "4K", "Full HD", "HD"]
        }
    }

    var durationFilterOptions: [String] {
        switch selectedSource {
        case .motionBG, .desktopHut:
            return ["全部"]
        default:
            return ["全部", "短视频 (<30s)", "中等 (30s-2m)", "长视频 (>2m)"]
        }
    }

    var categoryFilterOptions: [String] {
        switch selectedSource {
        case .motionBG:
            return ["全部", "Anime", "Nature", "Gaming", "Cyberpunk", "Space", "Cars", "Abstract"]
        case .desktopHut:
            return ["全部", "Anime", "Gaming", "Nature", "Fantasy", "Cars", "Space", "Minimal"]
        case .pexelsVideo:
            return ["全部", "Nature", "City", "Abstract", "Technology", "Ocean", "Space", "Minimal"]
        case .pixabayVideo:
            return ["全部", "Nature", "Background", "Abstract", "Technology", "Animals", "Space", "Loop"]
        case .workshop:
            return ["全部", "Scene", "Video", "Anime", "Relaxing", "Audio responsive"]
        }
    }

    func selectSource(_ source: MediaSource) {
        selectedSource = source
        let options = sortingOptionsForCurrentSource
        if !options.contains(selectedSorting) {
            selectedSorting = options.first ?? "热门"
        }
        if !categoryFilterOptions.contains(selectedCategory) {
            selectedCategory = "全部"
        }
        if resolutionFilterOptions.count <= 1 || !resolutionFilterOptions.contains(selectedResolution ?? "全部") {
            selectedResolution = nil
        }
        if !durationFilterOptions.contains(selectedDuration) {
            selectedDuration = "全部"
        }
    }

    // MARK: - Public Methods

    func loadInitialData() async {
        loadGeneration += 1
        let generation = loadGeneration
        currentPage = 1
        mediaItems = []
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
            let newItems: [MediaItem]

            // 根据选择的源、搜索词和排序获取数据
            newItems = try await fetchBySource()
            guard generation == loadGeneration else { return }
            let existingIds = Set(mediaItems.map(\.id))
            let uniqueNewItems = newItems.filter { !existingIds.contains($0.id) }

            if uniqueNewItems.isEmpty {
                hasMore = false
            } else {
                mediaItems.append(contentsOf: uniqueNewItems)
                currentPage += 1
                if selectedSource == .motionBG {
                    hasMore = false
                }
            }
        } catch {
            guard generation == loadGeneration else { return }
            errorMessage = "Failed to load media: \(error.localizedDescription)"
            print("[MediaExploreViewModel] Error: \(error)")
        }
    }

    func refresh() async {
        await loadInitialData()
    }

    func applyFilters() async {
        await loadInitialData()
    }

    // MARK: - Private Methods

    private func fetchBySource() async throws -> [MediaItem] {
        switch selectedSource {
        case .motionBG:
            return try await fetchMotionBGItems()
        case .workshop:
            return try await fetchWorkshopItems(query: searchQuery)
        case .pexelsVideo:
            return try await fetchPexelsVideos()
        case .pixabayVideo:
            return try await fetchPixabayVideos()
        case .desktopHut:
            return try await fetchDesktopHutItems()
        }
    }

    private func fetchMotionBGItems() async throws -> [MediaItem] {
        guard currentPage == 1 else { return [] }

        let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedQuery = resolvedCategoryQuery(fallback: trimmedQuery)
        let items = resolvedQuery.isEmpty
            ? try await mediaService.fetchHomePage()
            : try await repository.search(query: resolvedQuery, page: currentPage)
        let filtered = await applyClientFilters(to: items)
        return orderItems(filtered, for: selectedSorting)
    }

    private func fetchWorkshopItems(query: String) async throws -> [MediaItem] {
        let params = WorkshopSearchParams(
            query: query.trimmingCharacters(in: .whitespacesAndNewlines),
            sortBy: workshopSortOption,
            page: currentPage,
            pageSize: 20,
            tags: [],
            type: nil,
            contentLevel: "Everyone",
            resolution: workshopResolutionTag,
            days: workshopTrendDays
        )

        let response = try await workshopService.search(params: params)
        let items = workshopService.convertToMediaItems(response.items)
        let filtered = await applyClientFilters(to: items)
        return orderItems(filtered, for: selectedSorting)
    }

    private var workshopSortOption: WorkshopSearchParams.SortOption {
        switch selectedSorting {
        case "最新":
            return .created
        default:
            return .ranked
        }
    }

    private var workshopTrendDays: Int? {
        nil
    }

    private var workshopResolutionTag: String? {
        switch selectedResolution {
        case "4K":
            return "3840 x 2160"
        case "2K":
            return "2560 x 1440"
        case "1080P":
            return "1920 x 1080"
        default:
            return nil
        }
    }

    // MARK: - New Source Fetchers

    private func fetchPexelsVideos() async throws -> [MediaItem] {
        let trimmed = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedQuery = resolvedCategoryQuery(fallback: trimmed)
        let items: [MediaItem]
        if !resolvedQuery.isEmpty {
            items = try await pexelsService.searchVideos(query: resolvedQuery, page: currentPage, perPage: 20)
        } else {
            items = try await pexelsService.fetchPopularVideos(page: currentPage, perPage: 20)
        }
        let filtered = await applyClientFilters(to: items)
        return orderItems(filtered, for: selectedSorting)
    }

    private func fetchPixabayVideos() async throws -> [MediaItem] {
        let trimmed = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        let query = resolvedCategoryQuery(fallback: trimmed, defaultQuery: "wallpaper")

        // 根据用户选择的分辨率动态调整 API 参数
        let (minWidth, minHeight) = pixabayMinResolution

        let items = try await pixabayService.searchVideos(
            query: query,
            page: currentPage,
            perPage: 20,
            minWidth: minWidth,
            minHeight: minHeight,
            order: selectedSorting == "最新" ? "latest" : "popular"
        )
        let filtered = await applyClientFilters(to: items)

        // 客户端排序（Pixabay API 不支持服务端排序参数）
        return orderItems(filtered, for: selectedSorting)
    }

    private var pixabayMinResolution: (width: Int, height: Int) {
        guard let selectedResolution else {
            return (1920, 1080) // 默认 1080P
        }

        switch selectedResolution {
        case "4K", "4K+", "3840x2160":
            return (3840, 2160)
        case "2K", "2K+", "2560x1440":
            return (2560, 1440)
        case "Full HD", "1080P", "1080P+", "1920x1080":
            return (1920, 1080)
        case "HD", "720P", "1280x720":
            return (1280, 720)
        default:
            return (1920, 1080)
        }
    }

    private func fetchDesktopHutItems() async throws -> [MediaItem] {
        let trimmed = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedQuery = resolvedCategoryQuery(fallback: trimmed)
        let items: [MediaItem]
        if resolvedQuery.isEmpty {
            items = try await desktopHutService.fetchLatest(page: currentPage)
        } else {
            items = try await desktopHutService.search(query: resolvedQuery, page: currentPage)
        }
        let filtered = await applyClientFilters(to: items)
        return orderItems(filtered, for: selectedSorting)
    }

    private func resolvedCategoryQuery(fallback: String, defaultQuery: String = "") -> String {
        if !fallback.isEmpty { return fallback }
        guard selectedCategory != "全部" else { return defaultQuery }
        return selectedCategory.lowercased()
    }

    private func orderItems(_ items: [MediaItem], for sorting: String) -> [MediaItem] {
        switch sorting {
        case "最新":
            if items.contains(where: { $0.createdAt != nil }) {
                return items.sorted { lhs, rhs in
                    (lhs.createdAt ?? .distantPast) > (rhs.createdAt ?? .distantPast)
                }
            }
            return Array(items.reversed())
        case "随机":
            return items.shuffled()
        case "最多浏览":
            return items.sorted { ($0.viewCount ?? 0) > ($1.viewCount ?? 0) }
        case "最多收藏":
            return items.sorted { ($0.favoriteCount ?? 0) > ($1.favoriteCount ?? 0) }
        case "最高评分":
            return items.sorted { ($0.ratingScore ?? 0) > ($1.ratingScore ?? 0) }
        case "最多订阅":
            return items.sorted { ($0.subscriptionCount ?? 0) > ($1.subscriptionCount ?? 0) }
        case "高分辨率优先":
            return items.sorted { lhs, rhs in
                (lhs.pixelCount ?? 0) > (rhs.pixelCount ?? 0)
            }
        default:
            if items.contains(where: { ($0.viewCount ?? 0) + ($0.favoriteCount ?? 0) + ($0.subscriptionCount ?? 0) > 0 }) {
                return items.sorted { lhs, rhs in
                    let leftScore = (lhs.viewCount ?? 0) + (lhs.favoriteCount ?? 0) + (lhs.subscriptionCount ?? 0)
                    let rightScore = (rhs.viewCount ?? 0) + (rhs.favoriteCount ?? 0) + (rhs.subscriptionCount ?? 0)
                    return leftScore > rightScore
                }
            }
            return items
        }
    }

    private func applyClientFilters(to items: [MediaItem]) async -> [MediaItem] {
        let filtered = items.filter { item in
            matchesResolution(item) && matchesDuration(item)
        }

        // 如果过滤后结果太少，记录警告
        if filtered.count < 3 && items.count > 10 {
            NSLog("[MediaExploreViewModel] 警告：过滤后仅剩 \(filtered.count)/\(items.count) 个结果（源：\(selectedSource.displayName)，分辨率：\(selectedResolution ?? "全部")，时长：\(selectedDuration)）")
        }

        return filtered
    }

    private func matchesResolution(_ item: MediaItem) -> Bool {
        guard let selectedResolution, selectedResolution != "全部" else { return true }
        let resolutionText = (item.exactResolution ?? item.resolutionLabel).uppercased()

        switch selectedResolution {
        case "4K", "4K+", "3840x2160":
            return resolutionText.contains("3840") || resolutionText.contains("4096") || resolutionText.contains("4K")
        case "2K", "2K+", "2560x1440":
            return resolutionText.contains("2560") || resolutionText.contains("2K")
        case "1080P", "1080P+", "1920x1080", "Full HD":
            return resolutionText.contains("1920") || resolutionText.contains("1080") || resolutionText.contains("FULL HD")
        case "720P", "1280x720", "HD":
            return resolutionText.contains("1280") || resolutionText.contains("720") || resolutionText == "HD"
        default:
            return resolutionText.contains(selectedResolution.uppercased())
        }
    }

    private func matchesDuration(_ item: MediaItem) -> Bool {
        guard selectedDuration != "全部" else { return true }
        guard let duration = item.durationSeconds else {
            return selectedDuration == "未知时长"
        }

        switch selectedDuration {
        case "短视频 (<30s)":
            return duration < 30
        case "中等 (30s-2m)":
            return duration >= 30 && duration <= 120
        case "长视频 (>2m)":
            return duration > 120
        default:
            return true
        }
    }
}
