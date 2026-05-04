// Sources/Network/MyLiveWallpapersService.swift
import Foundation
import SwiftSoup

/// MyLiveWallpapers 服务 - 解析 mylivewallpapers.com
actor MyLiveWallpapersService {
    static let shared = MyLiveWallpapersService()

    private let networkService = NetworkService.shared
    private let baseURL = URL(string: "https://mylivewallpapers.com")!
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    private init() {}

    // MARK: - Public API

    func fetchLatest(page: Int = 1) async throws -> [MediaItem] {
        let url = page == 1 ? baseURL : baseURL.appendingPathComponent("page/\(page)/")
        return try await fetchAndParse(url: url)
    }

    func fetch4K(page: Int = 1) async throws -> [MediaItem] {
        let path = page == 1 ? "category/4k-3840x2160/" : "category/4k-3840x2160/page/\(page)/"
        let url = baseURL.appendingPathComponent(path)
        return try await fetchAndParse(url: url)
    }

    func search(query: String, page: Int = 1) async throws -> [MediaItem] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return try await fetchLatest(page: page) }

        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        var queryItems = [URLQueryItem(name: "s", value: trimmed)]
        if page > 1 {
            queryItems.append(URLQueryItem(name: "paged", value: String(page)))
        }
        components?.queryItems = queryItems
        guard let url = components?.url else { throw NetworkError.invalidResponse }

        return try await fetchAndParse(url: url)
    }

    // MARK: - Private Methods

    private func fetchAndParse(url: URL) async throws -> [MediaItem] {
        let html = try await networkService.fetchString(
            from: url,
            headers: [
                "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"
            ]
        )

        return try parseListPage(html: html)
    }

    private func parseListPage(html: String) throws -> [MediaItem] {
        let document = try SwiftSoup.parse(html)
        let posts = try document.select("a.post")

        var items: [MediaItem] = []
        var seen = Set<String>()

        for post in posts {
            guard let href = try? post.attr("href"), !href.isEmpty else { continue }
            guard let title = try? post.select(".archive-post-title").first()?.text(), !title.isEmpty else { continue }

            let slug = deriveSlug(from: href)
            guard !slug.isEmpty, seen.insert(slug).inserted else { continue }

            // Extract thumbnail from style attribute
            var thumbnailURL: URL?
            if let style = try? post.attr("style"), style.contains("background-image") {
                if let urlMatch = extractURLFromBackgroundImage(style) {
                    thumbnailURL = URL(string: urlMatch)
                }
            }

            // Extract date
            let dateString = (try? post.select(".archive-post-date").first()?.text()) ?? ""
            let createdAt = dateFormatter.date(from: dateString)

            // Extract resolution and category from CSS classes
            let classAttr = (try? post.attr("class")) ?? ""
            let has4K = classAttr.contains("category-4k-3840x2160")
            let resolutionLabel = has4K ? "4K" : "HD"
            let exactResolution = has4K ? "3840x2160" : nil

            // Extract category from classes
            let category = extractCategoryFromClasses(classAttr)

            // Extract tags from classes
            let tags = extractTagsFromClasses(classAttr)

            // Derive preview video URL from thumbnail
            var previewVideoURL: URL?
            if let thumbURL = thumbnailURL {
                previewVideoURL = derivePreviewVideoURL(from: thumbURL)
            }

            let item = MediaItem(
                slug: slug,
                title: title,
                pageURL: URL(string: href) ?? baseURL,
                thumbnailURL: thumbnailURL ?? baseURL,
                resolutionLabel: resolutionLabel,
                collectionTitle: category,
                summary: nil,
                previewVideoURL: previewVideoURL,
                fullVideoURL: nil,
                posterURL: thumbnailURL,
                tags: tags,
                exactResolution: exactResolution,
                durationSeconds: nil,
                downloadOptions: [],
                sourceName: "MyLiveWallpapers",
                isAnimatedImage: false,
                subscriptionCount: nil,
                favoriteCount: nil,
                viewCount: nil,
                ratingScore: nil,
                authorName: nil,
                fileSize: nil,
                createdAt: createdAt,
                updatedAt: nil
            )

            items.append(item)
        }

        return items
    }

    private func deriveSlug(from href: String) -> String {
        let cleaned = href
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            .replacingOccurrences(of: "https://mylivewallpapers.com/", with: "")
            .replacingOccurrences(of: "http://mylivewallpapers.com/", with: "")

        return "mlw_" + cleaned.replacingOccurrences(of: "/", with: "-")
    }

    private func extractURLFromBackgroundImage(_ style: String) -> String? {
        let pattern = #"url\(['"]?([^'")]+)['"]?\)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(style.startIndex..., in: style)
        guard let match = regex.firstMatch(in: style, range: range),
              let urlRange = Range(match.range(at: 1), in: style) else { return nil }
        return String(style[urlRange])
    }

    private func derivePreviewVideoURL(from thumbnailURL: URL) -> URL? {
        let urlString = thumbnailURL.absoluteString
        // Replace thumb-{name}.png with PREVIEW-{name}.mp4
        if let thumbRange = urlString.range(of: "thumb-") {
            var modified = urlString
            modified.replaceSubrange(thumbRange, with: "PREVIEW-")
            modified = modified.replacingOccurrences(of: ".png", with: ".mp4")
            return URL(string: modified)
        }
        return nil
    }

    private func extractCategoryFromClasses(_ classAttr: String) -> String? {
        let classes = classAttr.components(separatedBy: " ")
        for cls in classes {
            if cls.hasPrefix("category-") && !cls.contains("4k") && !cls.contains("mobile") {
                let category = cls.replacingOccurrences(of: "category-", with: "")
                return category.replacingOccurrences(of: "-", with: " ").capitalized
            }
        }
        return nil
    }

    private func extractTagsFromClasses(_ classAttr: String) -> [String] {
        let classes = classAttr.components(separatedBy: " ")
        var tags: [String] = []

        for cls in classes {
            if cls.hasPrefix("category-") && !cls.contains("4k") && !cls.contains("mobile") {
                let tag = cls.replacingOccurrences(of: "category-", with: "")
                    .replacingOccurrences(of: "-", with: " ")
                    .capitalized
                tags.append(tag)
            }
        }

        return tags
    }
}
