// Sources/OnlineModels/WorkshopModels.swift
import Foundation

// MARK: - Workshop Wallpaper Model

/// Wallpaper Engine Steam Workshop item
struct WorkshopWallpaper: Identifiable, Codable {
    let id: String              // Steam Workshop ID
    let title: String
    let description: String?
    let previewURL: URL?        // Preview image URL
    let author: WorkshopAuthor
    let fileSize: Int64?        // File size in bytes
    let fileURL: URL?           // Download link (requires SteamCMD)

    // Steam metadata
    let steamAppID: String      // Usually 431960 (Wallpaper Engine)
    let subscriptions: Int?     // Subscription count
    let favorites: Int?         // Favorite count
    let views: Int?             // View count
    let rating: Double?         // Rating 0-5

    // Wallpaper type
    let type: WallpaperType
    let tags: [String]
    let isAnimatedImage: Bool?

    // Timestamps
    let createdAt: Date?
    let updatedAt: Date?

    enum WallpaperType: String, Codable {
        case video = "video"
        case scene = "scene"           // Unity WebGL
        case web = "web"               // HTML/JS
        case application = "application"
        case image = "image"
        case pkg = "pkg"               // Packaged format
        case unknown = "unknown"
    }
}

// MARK: - Workshop Author
struct WorkshopAuthor: Codable {
    let steamID: String
    let name: String
    let avatarURL: URL?
}

// MARK: - Workshop Search Response
struct WorkshopSearchResponse: Codable {
    let items: [WorkshopWallpaper]
    let total: Int
    let page: Int
    let hasMore: Bool
}

// MARK: - Search Parameters
struct WorkshopSearchParams {
    var query: String = ""
    var sortBy: SortOption = .ranked
    var page: Int = 1
    var pageSize: Int = 20
    var tags: [String] = []
    var type: WorkshopWallpaper.WallpaperType?
    var contentLevel: String?
    var resolution: String?
    var days: Int?

    enum SortOption: String {
        case ranked = "ranked"           // Trending
        case updated = "updated"         // Recently updated
        case created = "created"         // Recently published
        case topRated = "toprated"       // Top rated
    }
}

// MARK: - Steam API Response Models

struct SteamPublishedFileResponse: Codable {
    let response: SteamPublishedFileQuery
}

struct SteamPublishedFileQuery: Codable {
    let result: Int?
    let resultcount: Int?
    let publishedfiledetails: [SteamPublishedFileDetail]?
}

struct SteamPublishedFileDetail: Codable {
    let publishedfileid: String
    let title: String
    let description: String?
    let preview_url: String?
    let file_url: String?
    let filename: String?
    let file_size: String?
    let creator: String
    let creator_app_id: Int?
    let consumer_app_id: Int?
    let subscriptions: Int?
    let favorited: Int?
    let lifetime_subscriptions: Int?
    let lifetime_favorited: Int?
    let views: Int?
    let score: Double?
    let vote_data: SteamPublishedFileVoteData?
    let time_created: Int?
    let time_updated: Int?
    let tags: [SteamTag]?
    let app_name: String?
}

struct SteamPublishedFileVoteData: Codable {
    let score: Double?
    let votes_up: Int?
    let votes_down: Int?
}

struct SteamTag: Codable {
    let tag: String
}

// MARK: - WorkshopWallpaper Extensions

extension WorkshopWallpaper {
    /// Merge HTML base info with Steam Web API details
    init(base: WorkshopWallpaper, detail: SteamPublishedFileDetail) {
        self.id = detail.publishedfileid
        self.title = detail.title.isEmpty ? base.title : detail.title
        self.description = detail.description
        self.previewURL = detail.preview_url.flatMap { URL(string: $0) } ?? base.previewURL
        self.author = WorkshopAuthor(
            steamID: detail.creator,
            name: base.author.name != "Unknown" ? base.author.name : "Unknown",
            avatarURL: base.author.avatarURL
        )
        self.fileSize = Int64(detail.file_size ?? "0")
        self.fileURL = detail.file_url.flatMap { URL(string: $0) }
        self.steamAppID = String(detail.consumer_app_id ?? 431960)
        self.subscriptions = detail.subscriptions ?? base.subscriptions ?? detail.lifetime_subscriptions
        self.favorites = detail.favorited ?? base.favorites ?? detail.lifetime_favorited
        self.views = detail.views ?? base.views
        self.rating = detail.vote_data?.score ?? detail.score ?? base.rating
        self.type = WorkshopWallpaper.detectType(fromTags: detail.tags?.map(\.tag) ?? [])
        self.tags = detail.tags?.map(\.tag) ?? []
        self.isAnimatedImage = base.isAnimatedImage
        self.createdAt = detail.time_created.flatMap { Date(timeIntervalSince1970: TimeInterval($0)) }
        self.updatedAt = detail.time_updated.flatMap { Date(timeIntervalSince1970: TimeInterval($0)) }
    }

    /// Detect type from tags
    static func detectType(fromTags tags: [String]) -> WallpaperType {
        let lowerTags = tags.map { $0.lowercased() }

        if lowerTags.contains("video") || lowerTags.contains("video wallpaper") {
            return .video
        } else if lowerTags.contains("web") || lowerTags.contains("web wallpaper") {
            return .web
        } else if lowerTags.contains("scene") {
            return .scene
        } else if lowerTags.contains("application") {
            return .application
        } else if lowerTags.contains("image") || lowerTags.contains("wallpaper") {
            return .video  // Most Wallpaper Engine items are video/animated
        }

        return .unknown
    }
}
