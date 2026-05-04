// Sources/Repositories/MediaRepository.swift
import Foundation
import SwiftUI

/// 动态媒体数据仓库（聚合 MotionBG + Steam Workshop）
final class MediaRepository: ObservableObject {
    static let shared = MediaRepository()

    // MARK: - Services
    private let mediaService = MediaService.shared
    private let pexelsService = PexelsService.shared
    private let pixabayService = PixabayService.shared
    private let desktopHutService = DesktopHutService.shared

    // MARK: - Cache
    private var heroCache: (data: [MediaItem], timestamp: Date)?
    private var popularCache: (data: [MediaItem], timestamp: Date)?
    private let cacheExpiration: TimeInterval = 6 * 3600  // 6 hours

    private init() {}

    // MARK: - Hero Items (动态壁纸轮播)

    /// 获取 Hero 动态壁纸（多维度加权算法）
    func fetchHeroItems() async throws -> [MediaItem] {
        NSLog("[MediaRepository] fetchHeroItems() 开始")

        if let cache = heroCache,
           Date().timeIntervalSince(cache.timestamp) < cacheExpiration {
            NSLog("[MediaRepository] 使用缓存的 Hero 数据: \(cache.data.count) 项")
            return cache.data
        }

        async let motionBGCandidates = fetchMotionBGCandidates()
        async let pexelsCandidates = fetchPexelsHeroCandidates()
        async let pixabayCandidates = fetchPixabayHeroCandidates()
        async let desktopCandidates = fetchDesktopHutHeroCandidates()

        let sources = try await [
            (motionBGCandidates, 0.35),
            (pexelsCandidates, 0.25),
            (pixabayCandidates, 0.25),
            (desktopCandidates, 0.15)
        ]

        let allCandidates = sources.flatMap { items, weight in
            items.map { item in
                (item, calculateQualityScore(item, sourceWeight: weight))
            }
        }

        let sorted = allCandidates.sorted { $0.1 > $1.1 }
        let final = applyDiversityRules(sorted, count: 8)

        NSLog("[MediaRepository] 最终返回 \(final.count) 个 Hero 项")
        heroCache = (final, Date())
        return final
    }

    /// 获取热门动态（热度 + 时效性）
    func fetchPopular() async throws -> [MediaItem] {
        NSLog("[MediaRepository] fetchPopular() 开始")

        // 检查缓存
        if let cache = popularCache,
           Date().timeIntervalSince(cache.timestamp) < cacheExpiration {
            NSLog("[MediaRepository] 使用缓存的 Popular 数据: \(cache.data.count) 项")
            return cache.data
        }

        NSLog("[MediaRepository] 获取 MotionBG 热门候选项...")
        // 获取候选池
        let motionBGPopular = try await fetchMotionBGPopularCandidates()
        NSLog("[MediaRepository] ✅ 获取到 \(motionBGPopular.count) 个热门候选项")

        // 评分公式：浏览量 40% + 收藏数 30% + 时效性 20% + 分辨率 10%
        let scored = motionBGPopular.map { item -> (MediaItem, Double) in
            let views = item.viewCount ?? item.subscriptionCount ?? 0
            let favorites = item.favoriteCount ?? 0
            let publishDate = item.createdAt ?? Date()

            let viewScore = min(Double(views) / 100_000.0, 1.0) * 0.4
            let favoriteScore = min(Double(favorites) / 10_000.0, 1.0) * 0.3
            let recencyScore = calculateRecencyScore(publishDate) * 0.2
            let resolutionScore = getResolutionScore(item.resolutionLabel) * 0.1
            return (item, viewScore + favoriteScore + recencyScore + resolutionScore)
        }

        let final = scored.sorted { $0.1 > $1.1 }
            .prefix(8)
            .map { $0.0 }

        NSLog("[MediaRepository] 最终返回 \(final.count) 个 Popular 项")

        // 更新缓存
        popularCache = (Array(final), Date())

        return Array(final)
    }

    /// 搜索媒体
    func search(query: String, page: Int = 1) async throws -> [MediaItem] {
        guard page == 1 else { return [] }
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let items = trimmed.isEmpty
            ? try await mediaService.fetchHomePage()
            : try await mediaService.search(query: trimmed)
        return Array(items.prefix(24))
    }

    /// 获取媒体详情
    func fetchDetail(slug: String) async throws -> MediaItem {
        try await mediaService.fetchDetail(slug: slug)
    }

    // MARK: - Private Helpers

    private func fetchMotionBGCandidates() async throws -> [MediaItem] {
        let items = try await mediaService.fetchHomePage()
        return Array(items.prefix(20))
    }

    private func fetchMotionBGPopularCandidates() async throws -> [MediaItem] {
        let items = try await mediaService.fetchHomePage()
        return Array(items.prefix(10))
    }

    private func fetchPexelsHeroCandidates() async throws -> [MediaItem] {
        do {
            return try await pexelsService.fetchPopularVideos(page: 1, perPage: 12)
        } catch {
            NSLog("[MediaRepository] Pexels Hero 获取失败: \(error.localizedDescription)")
            return []
        }
    }

    private func fetchPixabayHeroCandidates() async throws -> [MediaItem] {
        do {
            return try await pixabayService.fetchPopularVideos(page: 1, perPage: 12)
        } catch {
            NSLog("[MediaRepository] Pixabay Hero 获取失败: \(error.localizedDescription)")
            return []
        }
    }

    private func fetchDesktopHutHeroCandidates() async throws -> [MediaItem] {
        do {
            return try await desktopHutService.fetchLatest(page: 1)
        } catch {
            NSLog("[MediaRepository] DesktopHut Hero 获取失败: \(error.localizedDescription)")
            return []
        }
    }

    /// 计算质量得分
    private func calculateQualityScore(_ item: MediaItem, sourceWeight: Double) -> Double {
        // 使用新的字段名
        let views = item.viewCount ?? item.subscriptionCount ?? 0
        let favorites = item.favoriteCount ?? 0
        let publishDate = item.createdAt ?? Date()

        let normalizedViews = min(Double(views) / 100_000.0, 1.0)
        let normalizedFavorites = min(Double(favorites) / 10_000.0, 1.0)
        let resolutionScore = getResolutionScore(item.resolutionLabel)
        let recencyScore = calculateRecencyScore(publishDate)

        let qualityScore = (normalizedViews * 0.3)
                         + (normalizedFavorites * 0.3)
                         + (resolutionScore * 0.25)
                         + (recencyScore * 0.15)

        return qualityScore * sourceWeight
    }

    /// 应用多样性规则
    private func applyDiversityRules(_ candidates: [(MediaItem, Double)], count: Int) -> [MediaItem] {
        var result: [MediaItem] = []
        var usedAuthors = Set<String>()
        var tagCounts: [String: Int] = [:]

        for (item, _) in candidates {
            guard result.count < count else { break }

            // 规则 1: 同一作者最多 1 个
            if let author = item.authorName, !author.isEmpty {
                if usedAuthors.contains(author) {
                    continue
                }
                usedAuthors.insert(author)
            }

            // 规则 2: 同一标签最多 2 个
            if let tag = item.tags.first {
                if tagCounts[tag, default: 0] >= 2 {
                    continue
                }
                tagCounts[tag, default: 0] += 1
            }

            result.append(item)
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

    private func normalizeFavorites(_ favorites: Int) -> Double {
        min(Double(favorites) / 10_000.0, 1.0)
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
        heroCache = nil
        popularCache = nil
    }
}
