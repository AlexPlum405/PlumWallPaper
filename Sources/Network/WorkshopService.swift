// Sources/Network/WorkshopService.swift
import Foundation
import AppKit
import SwiftSoup

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

        var wallpapers = try parseWorkshopHTML(html)
        if !wallpapers.isEmpty {
            wallpapers = enrichWorkshopItems(wallpapers, params: params)
        }

        return WorkshopSearchResponse(
            items: wallpapers,
            total: wallpapers.count,
            page: params.page,
            hasMore: wallpapers.count >= params.pageSize
        )
    }

    // MARK: - HTML Parsing

    private func parseWorkshopHTML(_ html: String) throws -> [WorkshopWallpaper] {
        let document = try SwiftSoup.parse(html)

        var wallpapers: [WorkshopWallpaper] = []
        var seenIDs = Set<String>()

        for element in try document.select(".workshopItem") {
            guard let wallpaper = try parseWorkshopItem(element),
                  seenIDs.insert(wallpaper.id).inserted else {
                continue
            }
            wallpapers.append(wallpaper)
        }

        if wallpapers.isEmpty {
            wallpapers = try parseModernWorkshopHTML(document, seenIDs: &seenIDs)
        }

        return wallpapers
    }

    private func parseWorkshopItem(_ element: Element) throws -> WorkshopWallpaper? {
        let href = try element.select("a[href*=/sharedfiles/filedetails/?id=]").first()?.attr("href") ?? ""
        let id = extractWorkshopID(from: try element.attr("data-publishedfileid")) ?? extractWorkshopID(from: href)
        guard let id else { return nil }

        let title = try element.select(".workshopItemTitle").first()?.text()
            ?? element.select(".workshopItemDetailsTitle").first()?.text()
            ?? element.select("img[alt]").first()?.attr("alt")
            ?? "Untitled"

        let previewURL = try firstImageURL(in: element)
        let authorName = cleanAuthorName(
            try element.select(".workshopItemAuthorName, .workshopAuthor, .author, .creator").first()?.text()
        )
        let subscriptions = try parseNumber(from: element.select(".subscriptionCount, .subscriptions, .stats").first()?.text())
        let tags = try element.select(".workshopTags a, .tags a, .tag, [data-tag]").map { try $0.text() }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return WorkshopWallpaper(
            id: id,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            description: nil,
            previewURL: previewURL,
            author: WorkshopAuthor(steamID: "", name: authorName.isEmpty ? "Unknown" : authorName, avatarURL: nil),
            fileSize: nil,
            fileURL: nil,
            steamAppID: wallpaperEngineAppID,
            subscriptions: subscriptions,
            favorites: nil,
            views: nil,
            rating: nil,
            type: WorkshopWallpaper.detectType(fromTags: tags),
            tags: tags,
            isAnimatedImage: previewURL?.absoluteString.lowercased().contains(".gif") ?? false,
            createdAt: nil,
            updatedAt: nil
        )
    }

    private func parseModernWorkshopHTML(_ document: Document, seenIDs: inout Set<String>) throws -> [WorkshopWallpaper] {
        var wallpapers: [WorkshopWallpaper] = []

        for link in try document.select("a[href*=/sharedfiles/filedetails/?id=]") {
            let href = try link.attr("href")
            guard let id = extractWorkshopID(from: href),
                  seenIDs.insert(id).inserted else {
                continue
            }

            guard let previewURL = try firstImageURL(in: link) else {
                continue
            }

            let title = try link.select("img[alt]").first()?.attr("alt")
                ?? link.text().trimmingCharacters(in: .whitespacesAndNewlines)
            let authorName = try findAuthorName(near: link) ?? "Unknown"

            wallpapers.append(WorkshopWallpaper(
                id: id,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled" : title,
                description: nil,
                previewURL: previewURL,
                author: WorkshopAuthor(steamID: "", name: authorName, avatarURL: nil),
                fileSize: nil,
                fileURL: nil,
                steamAppID: wallpaperEngineAppID,
                subscriptions: nil,
                favorites: nil,
                views: nil,
                rating: nil,
                type: .unknown,
                tags: [],
                isAnimatedImage: previewURL.absoluteString.lowercased().contains(".gif"),
                createdAt: nil,
                updatedAt: nil
            ))
        }

        return wallpapers
    }

    private func enrichWorkshopItems(_ items: [WorkshopWallpaper], params: WorkshopSearchParams) -> [WorkshopWallpaper] {
        items.map { item in
            var tags = item.tags
            var type = item.type

            for tag in params.tags where !tags.contains(where: { $0.caseInsensitiveCompare(tag) == .orderedSame }) {
                tags.append(tag)
            }

            if let paramsType = params.type {
                type = paramsType
                let typeTag = paramsType.rawValue.capitalized
                if !tags.contains(where: { $0.caseInsensitiveCompare(typeTag) == .orderedSame }) {
                    tags.append(typeTag)
                }
            } else if type == .unknown {
                type = WorkshopWallpaper.detectType(fromTags: tags)
            }

            if type == .unknown {
                type = .video
            }

            return WorkshopWallpaper(
                id: item.id,
                title: item.title,
                description: item.description,
                previewURL: item.previewURL,
                author: item.author,
                fileSize: item.fileSize,
                fileURL: item.fileURL,
                steamAppID: item.steamAppID,
                subscriptions: item.subscriptions,
                favorites: item.favorites,
                views: item.views,
                rating: item.rating,
                type: type,
                tags: tags,
                isAnimatedImage: item.isAnimatedImage,
                createdAt: item.createdAt,
                updatedAt: item.updatedAt
            )
        }
    }

    private func firstImageURL(in element: Element) throws -> URL? {
        let selectors = [
            "img.workshopItemPreviewImage",
            ".workshopItemPreviewImage img",
            ".workshopItemPreviewImageHolder img",
            ".publishedfile_preview img",
            "img[src*=/ugc/]",
            "img[src]",
            "img[data-src]"
        ]

        for selector in selectors {
            guard let image = try element.select(selector).first() else { continue }
            let raw = try image.attr("src").isEmpty ? image.attr("data-src") : image.attr("src")
            if let url = normalizeURL(raw) {
                return url
            }
        }

        return nil
    }

    private func findAuthorName(near link: Element) throws -> String? {
        var current: Element? = link

        for _ in 0..<5 {
            guard let parent = current?.parent() else { break }
            current = parent

            for profileLink in try parent.select("a[href*=/profiles/], a[href*=/id/]") {
                let name = try profileLink.text().trimmingCharacters(in: .whitespacesAndNewlines)
                if !name.isEmpty && !name.contains("steamcommunity.com") {
                    return name
                }
            }
        }

        return nil
    }

    private func extractWorkshopID(from value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty, trimmed.range(of: #"^\d+$"#, options: .regularExpression) != nil {
            return trimmed
        }
        guard let range = trimmed.range(of: #"id=(\d+)"#, options: .regularExpression) else {
            return nil
        }
        let match = String(trimmed[range])
        return match.replacingOccurrences(of: "id=", with: "")
    }

    private func normalizeURL(_ rawValue: String) -> URL? {
        var raw = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return nil }

        if raw.hasPrefix("//") {
            raw = "https:" + raw
        }

        if raw.hasPrefix("/") {
            raw = "https://steamcommunity.com" + raw
        }

        return URL(string: raw)
    }

    private func cleanAuthorName(_ rawName: String?) -> String {
        let name = rawName?
            .replacingOccurrences(of: "\u{00a0}", with: " ")
            .replacingOccurrences(of: #"^\s*by\s+"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        return name.isEmpty ? "Unknown" : name
    }

    private func parseNumber(from text: String?) -> Int? {
        guard let text else { return nil }
        let normalized = text
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: " ", with: "")
            .lowercased()

        let multiplier: Double
        if normalized.contains("m") {
            multiplier = 1_000_000
        } else if normalized.contains("k") {
            multiplier = 1_000
        } else {
            multiplier = 1
        }

        let number = normalized.replacingOccurrences(of: #"[^0-9.]+"#, with: "", options: .regularExpression)
        guard let value = Double(number) else { return nil }
        return Int(value * multiplier)
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
