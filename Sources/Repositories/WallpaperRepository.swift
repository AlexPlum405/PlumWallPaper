// Sources/Repositories/WallpaperRepository.swift
import Foundation
import SwiftUI

/// 静态壁纸数据仓库（聚合 Wallhaven + 4K Wallpapers）
final class WallpaperRepository: ObservableObject {
    static let shared = WallpaperRepository()

    // MARK: - Services
    private let wallhavenService = WallhavenService.shared
    // 4K service 将在 agent 完成后可用
    // private let fourKService = FourKWallpapersService.shared

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
        let wallhavenCandidates = try await fetchWallhavenFeaturedCandidates()
        // TODO: 4K candidates when service is ready
        // let fourKCandidates = try await fetchFourKFeaturedCandidates()

        // 计算得分
        let scored = wallhavenCandidates.map { wallpaper -> (RemoteWallpaper, Double) in
            let score = calculateQualityScore(wallpaper, sourceWeight: 1.0)
            return (wallpaper, score)
        }

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

        print("[WallpaperRepository] 调用 wallhavenService.fetchLatest()")
        // 获取候选池
        let wallhavenLatest = try await wallhavenService.fetchLatest(limit: 20)
        print("[WallpaperRepository] ✅ 获取到 \(wallhavenLatest.count) 个壁纸")
        // TODO: 4K latest when service is ready

        // 评分公式：时效性 60% + 浏览量 20% + 分辨率 20%
        let scored = wallhavenLatest.map { wallpaper -> (RemoteWallpaper, Double) in
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

        let response = try await wallhavenService.search(parameters: parameters)
        return response.data
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
