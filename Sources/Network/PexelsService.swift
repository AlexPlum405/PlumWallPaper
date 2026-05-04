// Sources/Network/PexelsService.swift
import Foundation

actor PexelsService {
    static let shared = PexelsService()

    private let baseURL = "https://api.pexels.com"
    private let networkService = NetworkService.shared

    private init() {}

    // MARK: - Photos (→ RemoteWallpaper)

    func searchPhotos(
        query: String,
        page: Int = 1,
        perPage: Int = 20
    ) async throws -> [RemoteWallpaper] {
        guard let apiKey = await APIKeyManager.shared.apiKey(for: .pexels) else {
            throw NetworkError.invalidResponse
        }

        let urlString = "\(baseURL)/v1/search?query=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&per_page=\(perPage)&page=\(page)"
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidResponse
        }

        let response = try await networkService.fetch(
            PexelsPhotoResponse.self,
            from: url,
            headers: ["Authorization": apiKey]
        )

        return response.photos.map { mapPhotoToRemoteWallpaper($0) }
    }

    func fetchCurated(
        page: Int = 1,
        perPage: Int = 20
    ) async throws -> [RemoteWallpaper] {
        guard let apiKey = await APIKeyManager.shared.apiKey(for: .pexels) else {
            throw NetworkError.invalidResponse
        }

        let urlString = "\(baseURL)/v1/curated?per_page=\(perPage)&page=\(page)"
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidResponse
        }

        let response = try await networkService.fetch(
            PexelsPhotoResponse.self,
            from: url,
            headers: ["Authorization": apiKey]
        )

        return response.photos.map { mapPhotoToRemoteWallpaper($0) }
    }

    // MARK: - Videos (→ MediaItem)

    func searchVideos(
        query: String,
        page: Int = 1,
        perPage: Int = 20
    ) async throws -> [MediaItem] {
        guard let apiKey = await APIKeyManager.shared.apiKey(for: .pexels) else {
            throw NetworkError.invalidResponse
        }

        let urlString = "\(baseURL)/videos/search?query=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&per_page=\(perPage)&page=\(page)"
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidResponse
        }

        let response = try await networkService.fetch(
            PexelsVideoResponse.self,
            from: url,
            headers: ["Authorization": apiKey]
        )

        return response.videos.map { mapVideoToMediaItem($0) }
    }

    func fetchPopularVideos(
        page: Int = 1,
        perPage: Int = 20
    ) async throws -> [MediaItem] {
        guard let apiKey = await APIKeyManager.shared.apiKey(for: .pexels) else {
            throw NetworkError.invalidResponse
        }

        let urlString = "\(baseURL)/videos/popular?per_page=\(perPage)&page=\(page)"
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidResponse
        }

        let response = try await networkService.fetch(
            PexelsVideoResponse.self,
            from: url,
            headers: ["Authorization": apiKey]
        )

        return response.videos.map { mapVideoToMediaItem($0) }
    }

    // MARK: - Mapping

    private func mapPhotoToRemoteWallpaper(_ photo: PexelsPhoto) -> RemoteWallpaper {
        RemoteWallpaper(
            id: "pexels_\(photo.id)",
            url: photo.url,
            shortURL: nil,
            thumbURL: URL(string: photo.src.large),
            fullImageURL: URL(string: photo.src.original),
            resolution: "\(photo.width)x\(photo.height)",
            dimensionX: photo.width,
            dimensionY: photo.height,
            fileSize: 0,
            category: "general",
            purity: "sfw",
            views: 0,
            favorites: 0,
            uploadedAt: Date(),
            tags: nil,
            colors: photo.avgColor != nil ? [photo.avgColor!] : nil
        )
    }

    private func mapVideoToMediaItem(_ video: PexelsVideo) -> MediaItem {
        let bestFile = selectBestQualityFile(from: video.videoFiles)
        let hdFile = selectHDFile(from: video.videoFiles)

        return MediaItem(
            slug: "pexels_video_\(video.id)",
            title: "Pexels Video #\(video.id)",
            pageURL: URL(string: video.url)!,
            thumbnailURL: URL(string: video.image)!,
            resolutionLabel: bestFile.quality == "uhd" ? "4K" : bestFile.quality.uppercased(),
            collectionTitle: nil,
            summary: nil,
            previewVideoURL: URL(string: hdFile?.link ?? ""),
            fullVideoURL: URL(string: bestFile.link),
            posterURL: URL(string: video.image),
            tags: [],
            exactResolution: "\(video.width)x\(video.height)",
            durationSeconds: Double(video.duration),
            downloadOptions: [],
            sourceName: "Pexels",
            isAnimatedImage: nil,
            hasAudioTrack: nil,
            subscriptionCount: nil,
            favoriteCount: nil,
            viewCount: nil,
            ratingScore: nil,
            authorName: video.user.name,
            fileSize: Int64(bestFile.size ?? 0),
            createdAt: nil,
            updatedAt: nil
        )
    }

    private func selectBestQualityFile(from files: [PexelsVideoFile]) -> PexelsVideoFile {
        // Prefer UHD, then HD, then SD
        if let uhd = files.first(where: { $0.quality == "uhd" }) {
            return uhd
        }
        if let hd = files.first(where: { $0.quality == "hd" }) {
            return hd
        }
        return files.first ?? PexelsVideoFile(
            id: 0,
            quality: "sd",
            fileType: "video/mp4",
            width: 0,
            height: 0,
            fps: 0,
            link: "",
            size: nil
        )
    }

    private func selectHDFile(from files: [PexelsVideoFile]) -> PexelsVideoFile? {
        files.first(where: { $0.quality == "hd" })
    }
}

// MARK: - Codable Models

private struct PexelsPhotoResponse: Codable {
    let page: Int
    let perPage: Int
    let totalResults: Int
    let nextPage: String?
    let photos: [PexelsPhoto]

    enum CodingKeys: String, CodingKey {
        case page
        case perPage = "per_page"
        case totalResults = "total_results"
        case nextPage = "next_page"
        case photos
    }
}

private struct PexelsPhoto: Codable {
    let id: Int
    let width: Int
    let height: Int
    let url: String
    let photographer: String
    let photographerUrl: String
    let avgColor: String?
    let alt: String
    let src: PexelsPhotoSrc

    enum CodingKeys: String, CodingKey {
        case id, width, height, url, photographer, alt, src
        case photographerUrl = "photographer_url"
        case avgColor = "avg_color"
    }
}

private struct PexelsPhotoSrc: Codable {
    let original: String
    let large2x: String
    let large: String
    let medium: String
    let small: String
    let portrait: String
    let landscape: String
    let tiny: String
}

private struct PexelsVideoResponse: Codable {
    let page: Int
    let perPage: Int
    let totalResults: Int
    let videos: [PexelsVideo]

    enum CodingKeys: String, CodingKey {
        case page
        case perPage = "per_page"
        case totalResults = "total_results"
        case videos
    }
}

private struct PexelsVideo: Codable {
    let id: Int
    let width: Int
    let height: Int
    let duration: Int
    let url: String
    let image: String
    let user: PexelsUser
    let videoFiles: [PexelsVideoFile]
    let videoPictures: [PexelsVideoPicture]

    enum CodingKeys: String, CodingKey {
        case id, width, height, duration, url, image, user
        case videoFiles = "video_files"
        case videoPictures = "video_pictures"
    }
}

private struct PexelsUser: Codable {
    let id: Int
    let name: String
    let url: String
}

private struct PexelsVideoFile: Codable {
    let id: Int
    let quality: String
    let fileType: String
    let width: Int
    let height: Int
    let fps: Double
    let link: String
    let size: Int?

    enum CodingKeys: String, CodingKey {
        case id, quality, width, height, fps, link, size
        case fileType = "file_type"
    }
}

private struct PexelsVideoPicture: Codable {
    let id: Int
    let nr: Int
    let picture: String
}
