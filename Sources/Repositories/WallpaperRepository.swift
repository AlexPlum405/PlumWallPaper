// Sources/Repositories/WallpaperRepository.swift
import Foundation
import SwiftUI

/// 静态壁纸数据仓库（聚合 Wallhaven + 4K Wallpapers）
@MainActor
final class WallpaperRepository: ObservableObject {
    static let shared = WallpaperRepository()

    // MARK: - Services
    private let wallhavenService = WallhavenService.shared
    private let fourKService = FourKWallpapersService.shared

    // MARK: - Cache
    private var featuredCache: (data: [RemoteWallpaper], timestamp: Date)?
    private var latestCache: (data: [RemoteWallpaper], timestamp: Date)?
    private let cacheExpiration: TimeInterval = 6 * 3600  // 6 hours

    private init() {}

    // MARK: - Featured Wallpapers (Hero)

    /// 获取 Featured 壁纸（多维度加权算法）
    func fetchFeatured() async throws -> [RemoteWallpaper] {
        // 检查缓存
        if let cache = featuredCache,
           Date().timeIntervalSince(cache.timestamp) < cacheExpiration {
            return cache.data
        }

        // 获取候选池
        async let wallhavenCandidates = fetchWallhavenFeaturedCandidatesSafely()
        async let fourKCandidates = fetchFourKFeaturedCandidatesSafely(limit: 12)
        let (wallhaven, fourK) = await (wallhavenCandidates, fourKCandidates)
        let allCandidates = wallhaven + fourK
        guard !allCandidates.isEmpty else { throw NetworkError.invalidResponse }

        // 计算得分
        let scored = allCandidates.map { $0 }

        // 排序并应用多样性规则
        let sorted = scored.sorted { $0.1 > $1.1 }
        let final = applyDiversityRules(sorted, count: 24)

        // 更新缓存
        featuredCache = (final, Date())

        return final
    }

    /// 获取最新壁纸（最新 + 简化评分）
    func fetchLatest() async throws -> [RemoteWallpaper] {
        print("[WallpaperRepository] fetchLatest() 开始")

        // 检查缓存
        if let cache = latestCache,
           Date().timeIntervalSince(cache.timestamp) < cacheExpiration {
            print("[WallpaperRepository] 使用缓存数据: \(cache.data.count) 项")
            return cache.data
        }

        // 获取候选池
        async let wallhavenLatest = fetchWallhavenLatestSafely(limit: 20)
        async let fourKLatest = fetchFourKLatestSafely(limit: 12)
        let (wallhaven, fourK) = await (wallhavenLatest, fourKLatest)
        let latest = wallhaven + fourK
        guard !latest.isEmpty else { throw NetworkError.invalidResponse }

        // 评分公式：时效性 60% + 浏览量 20% + 分辨率 20%
        let scored = latest.map { wallpaper -> (RemoteWallpaper, Double) in
            let recencyScore = calculateRecencyScore(wallpaper.uploadedAt) * 0.6
            let viewScore = normalizeViews(wallpaper.views) * 0.2
            let resolutionScore = getResolutionScore(wallpaper.resolution) * 0.2
            return (wallpaper, recencyScore + viewScore + resolutionScore)
        }

        let final = scored.sorted { $0.1 > $1.1 }
            .prefix(8)
            .map { $0.0 }

        print("[WallpaperRepository] 最终返回 \(final.count) 项")

        // 更新缓存
        latestCache = (Array(final), Date())

        return Array(final)
    }

    /// 搜索壁纸
    func search(
        query: String,
        page: Int = 1,
        categories: String = "111",
        purity: String = "100",
        sorting: String = "date_added",
        order: String = "desc",
        topRange: String? = nil,
        resolutions: [String] = [],
        ratios: [String] = [],
        colors: [String] = []
    ) async throws -> [RemoteWallpaper] {
        let parameters = WallhavenAPI.SearchParameters(
            query: query,
            page: page,
            perPage: 24,
            categories: categories,
            purity: purity,
            sorting: sorting,
            order: order,
            topRange: topRange,
            resolutions: resolutions,
            ratios: ratios,
            colors: colors
        )

        do {
            let response = try await wallhavenService.search(parameters: parameters)
            return response.data
        } catch {
            return try await fourKService.search(
                query: query,
                page: page,
                perPage: 24,
                category: fourKCategory(fromWallhavenCategories: categories),
                usePopular: sorting == WallhavenAPI.SortingOption.toplist.rawValue
            )
        }
    }

    // MARK: - Private Helpers

    private func fetchWallhavenFeaturedCandidates() async throws -> [RemoteWallpaper] {
        // 组合多个来源
        async let topDay = wallhavenService.fetchTop(range: .oneDay, limit: 8)
        async let topWeek = wallhavenService.fetchTop(range: .oneWeek, limit: 6)
        async let latest = wallhavenService.fetchLatest(limit: 6)

        let (day, week, new) = try await (topDay, topWeek, latest)
        return day + week + new
    }

    private func fetchWallhavenFeaturedCandidatesSafely() async -> [(RemoteWallpaper, Double)] {
        do {
            return try await fetchWallhavenFeaturedCandidates().map {
                ($0, calculateQualityScore($0, sourceWeight: 1.0))
            }
        } catch {
            NSLog("[WallpaperRepository] Wallhaven featured fallback: \(error.localizedDescription)")
            return []
        }
    }

    private func fetchFourKFeaturedCandidatesSafely(limit: Int) async -> [(RemoteWallpaper, Double)] {
        do {
            return try await fourKService.fetchFeatured(limit: limit).map {
                ($0, calculateQualityScore($0, sourceWeight: 0.82))
            }
        } catch {
            NSLog("[WallpaperRepository] 4K featured fallback: \(error.localizedDescription)")
            return []
        }
    }

    private func fetchWallhavenLatestSafely(limit: Int) async -> [RemoteWallpaper] {
        do {
            return try await wallhavenService.fetchLatest(limit: limit)
        } catch {
            NSLog("[WallpaperRepository] Wallhaven latest fallback: \(error.localizedDescription)")
            return []
        }
    }

    private func fetchFourKLatestSafely(limit: Int) async -> [RemoteWallpaper] {
        do {
            return try await fourKService.fetchLatest(limit: limit)
        } catch {
            NSLog("[WallpaperRepository] 4K latest fallback: \(error.localizedDescription)")
            return []
        }
    }

    private func fourKCategory(fromWallhavenCategories categories: String) -> String? {
        switch categories {
        case "010":
            return "anime"
        case "001":
            return "people"
        default:
            return nil
        }
    }

    /// 计算质量得分
    private func calculateQualityScore(_ wallpaper: RemoteWallpaper, sourceWeight: Double) -> Double {
        let normalizedViews = min(Double(wallpaper.views) / 100_000.0, 1.0)
        let normalizedFavorites = min(Double(wallpaper.favorites) / 10_000.0, 1.0)
        let resolutionScore = getResolutionScore(wallpaper.resolution)
        let recencyScore = calculateRecencyScore(wallpaper.uploadedAt)

        let qualityScore = (normalizedViews * 0.3)
                         + (normalizedFavorites * 0.3)
                         + (resolutionScore * 0.25)
                         + (recencyScore * 0.15)

        return qualityScore * sourceWeight
    }

    /// 应用多样性规则
    private func applyDiversityRules(_ candidates: [(RemoteWallpaper, Double)], count: Int) -> [RemoteWallpaper] {
        var result: [RemoteWallpaper] = []
        var usedCategories: [String: Int] = [:]
        var usedColors: Set<String> = []

        for (wallpaper, _) in candidates {
            guard result.count < count else { break }

            // 规则 1: 同一分类最多 8 个
            if usedCategories[wallpaper.category, default: 0] >= 8 {
                continue
            }

            // 规则 2: 避免颜色过于单一
            if let firstColor = wallpaper.colors?.first {
                if usedColors.count >= 3 && !usedColors.contains(firstColor) {
                    // 已有 3 种颜色，优先使用已有颜色
                    if usedColors.count < 5 {
                        usedColors.insert(firstColor)
                    }
                } else {
                    usedColors.insert(firstColor)
                }
            }

            result.append(wallpaper)
            usedCategories[wallpaper.category, default: 0] += 1
        }

        return result
    }

    // MARK: - Scoring Helpers

    private func calculateRecencyScore(_ date: Date) -> Double {
        let daysSince = Date().timeIntervalSince(date) / (24 * 3600)
        if daysSince < 1 { return 1.0 }
        if daysSince < 7 { return 0.8 }
        if daysSince < 30 { return 0.6 }
        if daysSince < 90 { return 0.4 }
        return 0.2
    }

    private func normalizeViews(_ views: Int) -> Double {
        min(Double(views) / 100_000.0, 1.0)
    }

    private func getResolutionScore(_ resolution: String) -> Double {
        if resolution.contains("7680") || resolution.contains("8K") { return 1.0 }
        if resolution.contains("3840") || resolution.contains("4K") { return 0.9 }
        if resolution.contains("2560") || resolution.contains("2K") { return 0.7 }
        if resolution.contains("1920") || resolution.contains("1080") { return 0.5 }
        return 0.3
    }

    /// 清除缓存
    func clearCache() {
        featuredCache = nil
        latestCache = nil
    }
}
