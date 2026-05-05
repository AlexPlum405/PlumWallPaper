// Sources/Network/PixabayService.swift
import Foundation

actor PixabayService {
    static let shared = PixabayService()

    private let networkService = NetworkService.shared
    private let photoBaseURL = "https://pixabay.com/api/"
    private let videoBaseURL = "https://pixabay.com/api/videos/"

    // MARK: - Photos

    func searchPhotos(query: String, page: Int = 1, perPage: Int = 20, minWidth: Int = 1920, minHeight: Int = 1080, order: String = "popular") async throws -> [RemoteWallpaper] {
        guard let apiKey = await APIKeyManager.shared.apiKey(for: .pixabay) else {
            throw NetworkError.invalidResponse
        }

        var components = URLComponents(string: photoBaseURL)!
        components.queryItems = [
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "per_page", value: String(perPage)),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "image_type", value: "photo"),
            URLQueryItem(name: "min_width", value: String(minWidth)),
            URLQueryItem(name: "min_height", value: String(minHeight)),
            URLQueryItem(name: "order", value: order),
        ]

        guard let url = components.url else {
            throw NetworkError.invalidResponse
        }

        let response = try await networkService.fetch(PixabayPhotoResponse.self, from: url)
        return response.hits.map { mapPhotoToRemoteWallpaper($0) }
    }

    func fetchPopularPhotos(page: Int = 1, perPage: Int = 20, minWidth: Int = 1920, minHeight: Int = 1080) async throws -> [RemoteWallpaper] {
        try await searchPhotos(query: "wallpaper", page: page, perPage: perPage, minWidth: minWidth, minHeight: minHeight)
    }

    // MARK: - Videos

    func searchVideos(query: String, page: Int = 1, perPage: Int = 20, minWidth: Int = 1920, minHeight: Int = 1080, order: String = "popular") async throws -> [MediaItem] {
        guard let apiKey = await APIKeyManager.shared.apiKey(for: .pixabay) else {
            throw NetworkError.invalidResponse
        }

        var components = URLComponents(string: videoBaseURL)!
        components.queryItems = [
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "per_page", value: String(perPage)),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "min_width", value: String(minWidth)),
            URLQueryItem(name: "min_height", value: String(minHeight)),
            URLQueryItem(name: "order", value: order),
        ]

        guard let url = components.url else {
            throw NetworkError.invalidResponse
        }

        let response = try await networkService.fetch(PixabayVideoResponse.self, from: url)
        return response.hits.map { mapVideoToMediaItem($0) }
    }

    func fetchPopularVideos(page: Int = 1, perPage: Int = 20, minWidth: Int = 1920, minHeight: Int = 1080) async throws -> [MediaItem] {
        try await searchVideos(query: "wallpaper", page: page, perPage: perPage, minWidth: minWidth, minHeight: minHeight)
    }

    // MARK: - Mapping

    private func mapPhotoToRemoteWallpaper(_ hit: PixabayPhoto) -> RemoteWallpaper {
        RemoteWallpaper(
            id: "pixabay_\(hit.id)",
            url: hit.pageURL,
            shortURL: nil,
            thumbURL: URL(string: hit.webformatURL),
            fullImageURL: URL(string: hit.largeImageURL),
            resolution: "\(hit.imageWidth)x\(hit.imageHeight)",
            dimensionX: hit.imageWidth,
            dimensionY: hit.imageHeight,
            fileSize: Int64(hit.imageSize),
            category: "general",
            purity: "sfw",
            views: hit.views,
            favorites: hit.favorites ?? hit.likes,
            downloads: hit.downloads,
            uploadedAt: Date(),
            tags: nil,
            colors: nil
        )
    }

    private func mapVideoToMediaItem(_ hit: PixabayVideo) -> MediaItem {
        let tags = hit.tags.components(separatedBy: ", ")
        let title = tags.prefix(3).joined(separator: " ")

        let largeVideo = hit.videos.large
        let mediumVideo = hit.videos.medium
        let thumbnailURL = largeVideo.thumbnail
            .flatMap(URL.init(string:))
            ?? mediumVideo.thumbnail.flatMap(URL.init(string:))
            ?? hit.pictureID.flatMap { URL(string: "https://i.vimeocdn.com/video/\($0)_640x360.jpg") }
            ?? URL(string: hit.pageURL)!

        return MediaItem(
            slug: "pixabay_video_\(hit.id)",
            title: title.isEmpty ? "Pixabay Video" : title,
            pageURL: URL(string: hit.pageURL)!,
            thumbnailURL: thumbnailURL,
            resolutionLabel: "\(largeVideo.width)x\(largeVideo.height)",
            collectionTitle: nil,
            summary: nil,
            previewVideoURL: URL(string: mediumVideo.url),
            fullVideoURL: URL(string: largeVideo.url),
            posterURL: thumbnailURL,
            tags: tags,
            exactResolution: "\(largeVideo.width)x\(largeVideo.height)",
            durationSeconds: Double(hit.duration),
            downloadOptions: [],
            sourceName: "Pixabay",
            isAnimatedImage: nil,
            hasAudioTrack: nil,
            subscriptionCount: nil,
            favoriteCount: nil,
            viewCount: hit.views,
            ratingScore: nil,
            authorName: hit.user,
            fileSize: Int64(largeVideo.size),
            createdAt: nil,
            updatedAt: nil
        )
    }
}

// MARK: - Codable Models

private struct PixabayPhotoResponse: Codable {
    let total: Int
    let totalHits: Int
    let hits: [PixabayPhoto]

    enum CodingKeys: String, CodingKey {
        case total, hits
        case totalHits = "totalHits"
    }
}

private struct PixabayPhoto: Codable {
    let id: Int
    let pageURL: String
    let type: String
    let tags: String
    let previewURL: String
    let previewWidth: Int
    let previewHeight: Int
    let webformatURL: String
    let webformatWidth: Int
    let webformatHeight: Int
    let largeImageURL: String
    let imageWidth: Int
    let imageHeight: Int
    let imageSize: Int
    let views: Int
    let downloads: Int
    let favorites: Int?
    let likes: Int
    let user_id: Int
    let user: String
    let userImageURL: String

    enum CodingKeys: String, CodingKey {
        case id, type, tags, views, downloads, favorites, likes, user
        case pageURL = "pageURL"
        case previewURL = "previewURL"
        case previewWidth = "previewWidth"
        case previewHeight = "previewHeight"
        case webformatURL = "webformatURL"
        case webformatWidth = "webformatWidth"
        case webformatHeight = "webformatHeight"
        case largeImageURL = "largeImageURL"
        case imageWidth = "imageWidth"
        case imageHeight = "imageHeight"
        case imageSize = "imageSize"
        case user_id = "user_id"
        case userImageURL = "userImageURL"
    }
}

private struct PixabayVideoResponse: Codable {
    let total: Int
    let totalHits: Int
    let hits: [PixabayVideo]

    enum CodingKeys: String, CodingKey {
        case total, hits
        case totalHits = "totalHits"
    }
}

private struct PixabayVideo: Codable {
    let id: Int
    let pageURL: String
    let type: String
    let tags: String
    let duration: Int
    let pictureID: String?
    let videos: PixabayVideoFormats
    let views: Int
    let downloads: Int
    let likes: Int
    let userID: Int
    let user: String
    let userImageURL: String

    enum CodingKeys: String, CodingKey {
        case id, type, tags, duration, videos, views, downloads, likes, user
        case pageURL = "pageURL"
        case pictureID = "picture_id"
        case userID = "user_id"
        case userImageURL = "userImageURL"
    }
}

private struct PixabayVideoFormats: Codable {
    let large: PixabayVideoFormat
    let medium: PixabayVideoFormat
    let small: PixabayVideoFormat
    let tiny: PixabayVideoFormat
}

private struct PixabayVideoFormat: Codable {
    let url: String
    let width: Int
    let height: Int
    let size: Int
    let thumbnail: String?
}
