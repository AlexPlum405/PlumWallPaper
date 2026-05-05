// Sources/Network/UnsplashService.swift
import Foundation

actor UnsplashService {
    static let shared = UnsplashService()

    private let networkService = NetworkService.shared
    private let baseURL = "https://api.unsplash.com"
    private let dateFormatter = ISO8601DateFormatter()

    private init() {}

    // MARK: - Public API

    /// 搜索照片
    func searchPhotos(query: String, page: Int = 1, perPage: Int = 20, orderBy: String = "relevant") async throws -> [RemoteWallpaper] {
        guard let apiKey = await APIKeyManager.shared.apiKey(for: .unsplash) else {
            throw NetworkError.invalidResponse
        }

        var components = URLComponents(string: "\(baseURL)/search/photos")!
        components.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "per_page", value: String(perPage)),
            URLQueryItem(name: "order_by", value: orderBy),
            URLQueryItem(name: "orientation", value: "landscape")
        ]

        guard let url = components.url else {
            throw NetworkError.invalidResponse
        }

        let headers = ["Authorization": "Client-ID \(apiKey)"]
        let response = try await networkService.fetch(UnsplashSearchResponse.self, from: url, headers: headers)
        return response.results.map { mapPhoto($0) }
    }

    /// 获取随机照片
    func fetchRandom(query: String? = nil, count: Int = 20) async throws -> [RemoteWallpaper] {
        guard let apiKey = await APIKeyManager.shared.apiKey(for: .unsplash) else {
            throw NetworkError.invalidResponse
        }

        var components = URLComponents(string: "\(baseURL)/photos/random")!
        components.queryItems = [
            URLQueryItem(name: "count", value: String(count)),
            URLQueryItem(name: "orientation", value: "landscape")
        ]
        if let query, !query.isEmpty {
            components.queryItems?.append(URLQueryItem(name: "query", value: query))
        } else {
            components.queryItems?.append(URLQueryItem(name: "topics", value: "wallpapers"))
        }

        guard let url = components.url else {
            throw NetworkError.invalidResponse
        }

        let headers = ["Authorization": "Client-ID \(apiKey)"]
        let photos = try await networkService.fetch([UnsplashPhoto].self, from: url, headers: headers)
        return photos.map { mapPhoto($0) }
    }

    /// 获取壁纸主题照片
    func fetchWallpaperTopic(page: Int = 1, perPage: Int = 20, orderBy: String = "latest") async throws -> [RemoteWallpaper] {
        guard let apiKey = await APIKeyManager.shared.apiKey(for: .unsplash) else {
            throw NetworkError.invalidResponse
        }

        var components = URLComponents(string: "\(baseURL)/topics/wallpapers/photos")!
        components.queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "per_page", value: String(perPage)),
            URLQueryItem(name: "order_by", value: orderBy)
        ]

        guard let url = components.url else {
            throw NetworkError.invalidResponse
        }

        let headers = ["Authorization": "Client-ID \(apiKey)"]
        let photos = try await networkService.fetch([UnsplashPhoto].self, from: url, headers: headers)
        return photos.map { mapPhoto($0) }
    }

    // MARK: - Private Helpers

    private func mapPhoto(_ photo: UnsplashPhoto) -> RemoteWallpaper {
        let uploadedAt = dateFormatter.date(from: photo.created_at) ?? Date()

        return RemoteWallpaper(
            id: "unsplash_\(photo.id)",
            url: photo.links.html,
            shortURL: nil,
            thumbURL: URL(string: photo.urls.regular),
            fullImageURL: URL(string: photo.urls.full),
            resolution: "\(photo.width)x\(photo.height)",
            dimensionX: photo.width,
            dimensionY: photo.height,
            fileSize: 0,
            category: "general",
            purity: "sfw",
            views: 0,
            favorites: 0,
            uploadedAt: uploadedAt,
            tags: nil,
            colors: photo.color != nil ? [photo.color!] : nil
        )
    }
}

// MARK: - Codable Models

private struct UnsplashSearchResponse: Codable {
    let total: Int
    let total_pages: Int
    let results: [UnsplashPhoto]
}

private struct UnsplashPhoto: Codable {
    let id: String
    let created_at: String
    let width: Int
    let height: Int
    let color: String?
    let blur_hash: String?
    let description: String?
    let alt_description: String?
    let urls: UnsplashURLs
    let links: UnsplashLinks
    let user: UnsplashUser

    enum CodingKeys: String, CodingKey {
        case id, created_at, width, height, color, blur_hash, description, alt_description, urls, links, user
    }
}

private struct UnsplashURLs: Codable {
    let raw: String
    let full: String
    let regular: String
    let small: String
    let thumb: String
}

private struct UnsplashLinks: Codable {
    let `self`: String
    let html: String
    let download: String

    enum CodingKeys: String, CodingKey {
        case `self` = "self"
        case html, download
    }
}

private struct UnsplashUser: Codable {
    let id: String
    let username: String
    let name: String
}
