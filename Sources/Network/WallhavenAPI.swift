// Sources/Network/WallhavenAPI.swift
import Foundation

/// Wallhaven API 配置和端点构建器
/// API Rate Limits: 45 requests per minute
/// For more details, see: https://wallhaven.cc/help/api
enum WallhavenAPI {
    static let baseURL = "https://wallhaven.cc/api/v1"

    struct SearchParameters {
        var query: String = ""
        var page: Int = 1
        var perPage: Int = 24
        var categories: String = "111"  // general, anime, people
        var purity: String = "100"      // sfw only by default
        var sorting: String = "date_added"
        var order: String = "desc"
        var topRange: String?           // 1d, 1w, 1M, 3M, 6M, 1y
        var atleast: String?            // minimum resolution
        var resolutions: [String] = []
        var ratios: [String] = []
        var colors: [String] = []
        var seed: String?               // for random sorting
    }

    enum SortingOption: String {
        case dateAdded = "date_added"
        case relevance = "relevance"
        case random = "random"
        case views = "views"
        case favorites = "favorites"
        case toplist = "toplist"
    }

    enum TopRange: String {
        case oneDay = "1d"
        case oneWeek = "1w"
        case oneMonth = "1M"
        case threeMonths = "3M"
        case sixMonths = "6M"
        case oneYear = "1y"
    }

    enum Endpoint {
        case search(SearchParameters)
        case wallpaper(id: String)
    }

    static func url(for endpoint: Endpoint, apiKey: String? = nil) -> URL? {
        switch endpoint {
        case .search(let parameters):
            return buildSearchURL(parameters: parameters, apiKey: apiKey)
        case .wallpaper(let id):
            return URL(string: "\(baseURL)/w/\(id)")
        }
    }

    static func authenticationHeaders(apiKey: String?) -> [String: String] {
        var headers = ["Accept": "application/json"]
        if let apiKey = apiKey?.trimmingCharacters(in: .whitespacesAndNewlines), !apiKey.isEmpty {
            headers["X-API-Key"] = apiKey
        }
        return headers
    }

    private static func buildSearchURL(parameters: SearchParameters, apiKey: String? = nil) -> URL? {
        guard var components = URLComponents(string: "\(baseURL)/search") else {
            return nil
        }

        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "page", value: String(max(parameters.page, 1))),
            URLQueryItem(name: "per_page", value: String(parameters.perPage)),
            URLQueryItem(name: "categories", value: parameters.categories),
            URLQueryItem(name: "purity", value: parameters.purity),
            URLQueryItem(name: "sorting", value: parameters.sorting),
            URLQueryItem(name: "order", value: parameters.order)
        ]

        let trimmedQuery = parameters.query.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedQuery.isEmpty {
            queryItems.append(URLQueryItem(name: "q", value: trimmedQuery))
        }

        // toplist 排序时必须提供 topRange
        if parameters.sorting == "toplist" {
            let range = parameters.topRange ?? "1M"
            queryItems.append(URLQueryItem(name: "topRange", value: range))
        }

        if let atleast = parameters.atleast, !atleast.isEmpty {
            queryItems.append(URLQueryItem(name: "atleast", value: atleast))
        }

        let resolutions = parameters.resolutions.filter { !$0.isEmpty }
        if !resolutions.isEmpty {
            queryItems.append(URLQueryItem(name: "resolutions", value: resolutions.joined(separator: ",")))
        }

        let ratios = parameters.ratios.filter { !$0.isEmpty }
        if !ratios.isEmpty {
            queryItems.append(URLQueryItem(name: "ratios", value: ratios.joined(separator: ",")))
        }

        if let firstColor = parameters.colors.first(where: { !$0.isEmpty }) {
            queryItems.append(URLQueryItem(name: "colors", value: firstColor))
        }

        // random 排序时可选 seed
        if parameters.sorting == "random", let seed = parameters.seed, !seed.isEmpty {
            queryItems.append(URLQueryItem(name: "seed", value: seed))
        }

        // API Key 认证 (query 参数方式)
        if let apiKey = apiKey?.trimmingCharacters(in: .whitespacesAndNewlines), !apiKey.isEmpty {
            queryItems.append(URLQueryItem(name: "apikey", value: apiKey))
        }

        components.queryItems = queryItems
        return components.url
    }
}
