// Sources/Network/FourKWallpapersService.swift
import Foundation

/// 4KWallpapers 数据源服务
/// 当 Wallhaven 主站不可用时，4KWallpapers 作为备用源
/// 通过 HTML 抓取 + SwiftSoup 解析获取数据
actor FourKWallpapersService {
    static let shared = FourKWallpapersService()

    private let networkService = NetworkService.shared
    private let parser = FourKWallpapersParser()

    // MARK: - 公开 API

    /// 搜索壁纸（映射为标准 RemoteWallpaper 格式）
    func search(
        query: String = "",
        page: Int = 1,
        perPage: Int = 24,
        category: String? = nil,
        usePopular: Bool = false
    ) async throws -> [RemoteWallpaper] {
        let url: String
        if !query.isEmpty {
            url = parser.buildSearchURL(query: query, page: page)
        } else if usePopular {
            if let category = category {
                // 4K 没有 popular+category 组合，回退到分类页（最新）
                url = parser.buildListURL(category: category, page: page)
            } else {
                url = parser.buildPopularURL(page: page)
            }
        } else if let category = category {
            url = parser.buildListURL(category: category, page: page)
        } else {
            url = parser.buildListURL(page: page)
        }

        let html = try await fetchHTML(from: url)
        let result = try parser.parseWallpaperList(html: html, url: url)

        return result.wallpapers.map { mapToRemoteWallpaper($0) }
    }

    /// 获取精选/热门壁纸（首页轮播用）
    func fetchFeatured(limit: Int = 24) async throws -> [RemoteWallpaper] {
        let url = parser.buildPopularURL(page: 1)
        let html = try await fetchHTML(from: url)
        let result = try parser.parseWallpaperList(html: html, url: url)
        return result.wallpapers.prefix(limit).map { mapToRemoteWallpaper($0) }
    }

    /// 获取最新壁纸
    func fetchLatest(limit: Int = 8) async throws -> [RemoteWallpaper] {
        let url = parser.buildListURL(page: 1)
        let html = try await fetchHTML(from: url)
        let result = try parser.parseWallpaperList(html: html, url: url)
        return result.wallpapers.prefix(limit).map { mapToRemoteWallpaper($0) }
    }

    /// 获取 Top 壁纸（热门排序）
    func fetchTop(limit: Int = 8) async throws -> [RemoteWallpaper] {
        let url = parser.buildPopularURL(page: 1)
        let html = try await fetchHTML(from: url)
        let result = try parser.parseWallpaperList(html: html, url: url)
        return result.wallpapers.prefix(limit).map { mapToRemoteWallpaper($0) }
    }

    /// 获取指定分类的壁纸
    func fetchCategory(_ category: String, page: Int = 1) async throws -> [RemoteWallpaper] {
        try await search(page: page, category: category)
    }

    /// 获取可用分类列表
    func getCategories() -> [FourKCategory] {
        FourKWallpapersParser.categories
    }

    /// 从详情页解析原图下载 URL
    /// 4KWallpapers 的原图 URL（/images/wallpapers/{name}-{W}x{H}-{id}.jpg）只能从详情页获取
    /// - Parameter wallpaper: 标准 RemoteWallpaper 模型（需要包含 url 字段即详情页链接）
    /// - Returns: 原图 URL 字符串，失败返回 nil
    func fetchOriginalImageURL(for wallpaper: RemoteWallpaper) async -> String? {
        // 4K 壁纸的 url 字段存的是详情页链接
        let detailURLString = wallpaper.url
        guard !detailURLString.isEmpty else {
            return nil
        }

        do {
            let html = try await fetchHTML(from: detailURLString)
            return parser.parseOriginalImageURL(from: html)
        } catch {
            return nil
        }
    }

    // MARK: - HTML 获取

    private func fetchHTML(from urlString: String) async throws -> String {
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidResponse
        }

        // 4KWallpapers 是 HTML 页面，需要指定 UA 避免被拦截
        let data = try await networkService.fetchData(
            from: url,
            headers: [
                "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
                "Accept-Language": "en-US,en;q=0.9",
                "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
            ]
        )

        guard let html = String(data: data, encoding: .utf8) else {
            throw NetworkError.decodingError
        }

        return html
    }

    // MARK: - 字段映射：Wallpaper4K → RemoteWallpaper

    private func mapToRemoteWallpaper(_ w: Wallpaper4K) -> RemoteWallpaper {
        // 判断 originalURL 是否是真正的原图 URL（以 /images/wallpapers/ 开头且包含分辨率）
        let isOriginalImage = w.originalURL.contains("/images/wallpapers/") && w.originalURL.contains("x")

        // 缩略图 URL
        let thumbURL = URL(string: w.thumbnailURL)

        // 全图 URL（用于详情页/轮播图展示）
        let fullImageURL = URL(string: isOriginalImage ? w.originalURL : w.hdThumbnailURL)

        // 从关键词推断分类
        let category = inferCategory(from: w.keywords, tags: w.tags)

        // 分辨率
        let width = max(w.width, 100)
        let height = max(w.height, 100)
        let resolution = "\(width)x\(height)"

        // 标签
        let tags = w.tags.enumerated().map { index, tag in
            APITag(
                id: index,
                name: tag.name,
                alias: nil,
                categoryID: 0,
                category: category,
                purity: "sfw"
            )
        }

        // 文件大小（未知，设为 0）
        let fileSize: Int64 = 0

        // 上传时间（未知，使用当前时间）
        let uploadedAt = Date()

        // 颜色（未提供）
        let colors: [String] = []

        return RemoteWallpaper(
            id: "4k_\(w.id)",
            url: w.detailURL,
            shortURL: nil,
            thumbURL: thumbURL,
            fullImageURL: fullImageURL,
            resolution: resolution,
            dimensionX: width,
            dimensionY: height,
            fileSize: fileSize,
            category: category,
            purity: "sfw",   // 4KWallpapers 默认都是 SFW
            views: 0,
            favorites: 0,
            uploadedAt: uploadedAt,
            tags: tags.isEmpty ? nil : tags,
            colors: colors.isEmpty ? nil : colors
        )
    }

    // MARK: - 辅助方法

    /// 从关键词和标签推断分类（映射到 Wallhaven 的 general/anime/people）
    private func inferCategory(from keywords: [String], tags: [Wallpaper4K.Wallpaper4KTag]) -> String {
        let allText = (keywords + tags.map(\.name)).joined(separator: " ").lowercased()

        // 动漫相关
        let animeKeywords = ["anime", "manga", "otaku", "waifu", "kawaii", "cute"]
        if animeKeywords.contains(where: { allText.contains($0) }) {
            return "anime"
        }

        // 人物相关
        let peopleKeywords = ["people", "girl", "woman", "man", "boy", "portrait", "model"]
        if peopleKeywords.contains(where: { allText.contains($0) }) {
            return "people"
        }

        // 默认 general
        return "general"
    }
}


