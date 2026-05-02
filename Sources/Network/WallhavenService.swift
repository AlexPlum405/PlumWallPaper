// Sources/Network/WallhavenService.swift
import Foundation

@MainActor
final class WallhavenService: ObservableObject {
    static let shared = WallhavenService()

    private let networkService = NetworkService.shared
    private var apiKey: String?

    private init() {}

    func setAPIKey(_ key: String?) {
        self.apiKey = key
    }

    /// 搜索壁纸
    func search(parameters: WallhavenAPI.SearchParameters) async throws -> WallhavenResponse {
        guard let url = WallhavenAPI.url(for: .search(parameters), apiKey: apiKey) else {
            throw NetworkError.invalidResponse
        }

        let headers = WallhavenAPI.authenticationHeaders(apiKey: apiKey)
        return try await networkService.fetch(WallhavenResponse.self, from: url, headers: headers)
    }

    /// 获取 Featured 壁纸（今日热榜 + 横向比例）
    func fetchFeatured(limit: Int = 24) async throws -> [RemoteWallpaper] {
        let parameters = WallhavenAPI.SearchParameters(
            page: 1,
            perPage: limit,
            categories: "111",
            purity: "100",
            sorting: WallhavenAPI.SortingOption.toplist.rawValue,
            order: "desc",
            topRange: WallhavenAPI.TopRange.oneDay.rawValue,
            ratios: ["16x9", "16x10", "21x9", "32x9", "48x9"]
        )

        let response = try await search(parameters: parameters)
        return response.data.filter { $0.dimensionX > $0.dimensionY }
    }

    /// 获取最新壁纸
    func fetchLatest(limit: Int = 24) async throws -> [RemoteWallpaper] {
        print("[WallhavenService] fetchLatest() 开始, limit=\(limit)")

        let parameters = WallhavenAPI.SearchParameters(
            page: 1,
            perPage: limit,
            categories: "111",
            purity: "100",
            sorting: WallhavenAPI.SortingOption.dateAdded.rawValue,
            order: "desc"
        )

        print("[WallhavenService] 调用 search() with parameters")
        let response = try await search(parameters: parameters)
        print("[WallhavenService] ✅ 获取到 \(response.data.count) 个壁纸")
        return response.data
    }

    /// 获取热门壁纸
    func fetchTop(range: WallhavenAPI.TopRange = .oneMonth, limit: Int = 24) async throws -> [RemoteWallpaper] {
        let parameters = WallhavenAPI.SearchParameters(
            page: 1,
            perPage: limit,
            categories: "111",
            purity: "100",
            sorting: WallhavenAPI.SortingOption.toplist.rawValue,
            order: "desc",
            topRange: range.rawValue
        )

        let response = try await search(parameters: parameters)
        return response.data
    }

    /// 获取单个壁纸详情
    func fetchWallpaper(id: String) async throws -> RemoteWallpaper {
        guard let url = WallhavenAPI.url(for: .wallpaper(id: id), apiKey: apiKey) else {
            throw NetworkError.invalidResponse
        }

        let headers = WallhavenAPI.authenticationHeaders(apiKey: apiKey)
        let response: WallpaperDetailResponse = try await networkService.fetch(WallpaperDetailResponse.self, from: url, headers: headers)
        return response.data
    }
}

/// 单个壁纸详情响应
struct WallpaperDetailResponse: Codable {
    let data: RemoteWallpaper
}
