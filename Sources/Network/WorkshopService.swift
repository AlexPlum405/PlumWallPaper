// Sources/Network/WorkshopService.swift
import Foundation
import AppKit

// MARK: - Workshop Service

/// Handles Wallpaper Engine Steam Workshop search and browsing
@MainActor
class WorkshopService: ObservableObject {
    static let shared = WorkshopService()

    // MARK: - Published State

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchResults: [WorkshopWallpaper] = []
    @Published var hasMorePages = false

    // MARK: - Configuration

    private let wallpaperEngineAppID = "431960"
    private let steamAPIBase = "https://api.steampowered.com"
    private let workshopBrowseBase = "https://steamcommunity.com/workshop/browse/"
    private var currentPage = 1
    private let pageSize = 20

    // MARK: - Search

    func search(params: WorkshopSearchParams) async throws -> WorkshopSearchResponse {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
            currentPage = params.page
        }

        defer {
            isLoading = false
        }

        let result = try await searchHTML(params: params)
        return result
    }

    private func sortValue(for sort: WorkshopSearchParams.SortOption) -> String {
        switch sort {
        case .ranked: return "trend"
        case .updated: return "lastupdated"
        case .created: return "mostrecent"
        case .topRated: return "toprated"
        }
    }

    private func searchHTML(params: WorkshopSearchParams) async throws -> WorkshopSearchResponse {
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "appid", value: wallpaperEngineAppID),
            URLQueryItem(name: "searchtext", value: params.query),
            URLQueryItem(name: "child_publishedfileid", value: "0"),
            URLQueryItem(name: "browsesort", value: sortValue(for: params.sortBy)),
            URLQueryItem(name: "section", value: "readytouseitems"),
            URLQueryItem(name: "created_filetype", value: "0"),
            URLQueryItem(name: "updated_filters", value: "1")
        ]

        // Build required tags
        var requiredTags: [String] = []
        if let type = params.type {
            switch type {
            case .video: requiredTags.append("Video")
            case .scene: requiredTags.append("Scene")
            case .web: requiredTags.append("Web")
            case .application: requiredTags.append("Application")
            default: break
            }
        }
        if !params.tags.isEmpty {
            requiredTags.append(contentsOf: params.tags)
        }
        // Force SFW content only
        requiredTags.append("Everyone")
        if let resolution = params.resolution {
            requiredTags.append(resolution)
        }
        for tag in requiredTags {
            queryItems.append(URLQueryItem(name: "requiredtags[]", value: tag))
        }

        queryItems.append(URLQueryItem(name: "p", value: String(params.page)))
        queryItems.append(URLQueryItem(name: "num_per_page", value: String(params.pageSize)))

        if params.sortBy == .ranked, let days = params.days {
            queryItems.append(URLQueryItem(name: "days", value: String(days)))
        }

        var components = URLComponents(string: workshopBrowseBase)
        components?.queryItems = queryItems

        guard let url = components?.url else {
            throw WorkshopError.invalidURL
        }

        // Use NetworkService for the request
        let data = try await NetworkService.shared.fetchData(from: url, headers: [
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"
        ])

        guard let html = String(data: data, encoding: .utf8) else {
            throw WorkshopError.apiError("Unable to parse HTML response")
        }

        var wallpapers: [WorkshopWallpaper] = []
        // Parse HTML (simplified - full implementation would use SwiftSoup)
        // For now, return empty array as placeholder

        return WorkshopSearchResponse(
            items: wallpapers,
            total: wallpapers.count,
            page: params.page,
            hasMore: wallpapers.count >= params.pageSize
        )
    }

    func loadMore(currentParams: WorkshopSearchParams) async throws -> WorkshopSearchResponse {
        var params = currentParams
        params.page = currentPage + 1
        return try await search(params: params)
    }
}

// MARK: - WorkshopWallpaper → MediaItem Conversion

extension WorkshopService {
    func convertToMediaItem(_ wallpaper: WorkshopWallpaper) -> MediaItem {
        var downloadOptions: [MediaDownloadOption] = []

        if let fileURL = wallpaper.fileURL {
            let option = MediaDownloadOption(
                label: "Workshop",
                fileSizeLabel: formatFileSize(wallpaper.fileSize),
                detailText: "\(wallpaper.type.rawValue.capitalized)",
                remoteURL: fileURL
            )
            downloadOptions = [option]
        }

        return MediaItem(
            slug: "workshop_\(wallpaper.id)",
            title: wallpaper.title,
            pageURL: URL(string: "https://steamcommunity.com/sharedfiles/filedetails/?id=\(wallpaper.id)")!,
            thumbnailURL: wallpaper.previewURL ?? URL(string: "https://steamcommunity.com/favicon.ico")!,
            resolutionLabel: wallpaper.type.rawValue.capitalized,
            collectionTitle: wallpaper.tags.first,
            summary: wallpaper.description,
            previewVideoURL: nil,
            posterURL: wallpaper.previewURL,
            tags: wallpaper.tags,
            exactResolution: nil,
            durationSeconds: nil,
            downloadOptions: downloadOptions,
            sourceName: "Wallpaper Engine",
            isAnimatedImage: wallpaper.isAnimatedImage,
            subscriptionCount: wallpaper.subscriptions,
            favoriteCount: wallpaper.favorites,
            viewCount: wallpaper.views,
            ratingScore: wallpaper.rating,
            authorName: wallpaper.author.name != "Unknown" ? wallpaper.author.name : nil,
            fileSize: wallpaper.fileSize,
            createdAt: wallpaper.createdAt,
            updatedAt: wallpaper.updatedAt
        )
    }

    func convertToMediaItems(_ wallpapers: [WorkshopWallpaper]) -> [MediaItem] {
        wallpapers.map { convertToMediaItem($0) }
    }

    private func formatFileSize(_ bytes: Int64?) -> String {
        guard let bytes = bytes else { return "Unknown" }
        let mb = Double(bytes) / 1024 / 1024
        if mb >= 1024 {
            return String(format: "%.1f GB", mb / 1024)
        }
        return String(format: "%.1f MB", mb)
    }
}

// MARK: - Error Types

enum WorkshopError: LocalizedError {
    case invalidURL
    case apiError(String)
    case steamcmdNotFound
    case credentialsRequired
    case invalidCredentials
    case sessionExpired
    case loginTimeout
    case guardCodeRequired(String)
    case timeout
    case downloadIncomplete
    case downloadFailed(String)
    case executionFailed(String)
    case workshopNotSupported

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .apiError(let msg): return msg
        case .steamcmdNotFound: return "SteamCMD not found"
        case .credentialsRequired: return "Steam credentials required"
        case .invalidCredentials: return "Invalid Steam credentials or 2FA required"
        case .sessionExpired: return "Steam login expired, please re-authenticate in settings"
        case .loginTimeout: return "Steam login timeout, please check network connection"
        case .guardCodeRequired(let msg): return msg
        case .timeout: return "SteamCMD response timeout"
        case .downloadIncomplete: return "Download incomplete"
        case .downloadFailed(let msg): return msg
        case .executionFailed(let msg): return msg
        case .workshopNotSupported: return "Not a Workshop item"
        }
    }
}

enum SteamCMDStatus {
    case ready
    case notInstalled
    case error(String)
    case downloading
}

