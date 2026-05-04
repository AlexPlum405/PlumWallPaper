import Foundation
import SwiftSoup

actor DesktopHutService {
    static let shared = DesktopHutService()

    private let baseURL = "https://www.desktophut.com"
    private let networkService = NetworkService.shared

    private init() {}

    func fetchLatest(page: Int = 1) async throws -> [MediaItem] {
        let url = URL(string: "\(baseURL)/?page=\(page)")!
        return try await fetchWallpapers(from: url)
    }

    func search(query: String, page: Int = 1) async throws -> [MediaItem] {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let url = URL(string: "\(baseURL)/?s=\(encodedQuery)&page=\(page)")!
        return try await fetchWallpapers(from: url)
    }

    private func fetchWallpapers(from url: URL) async throws -> [MediaItem] {
        let headers = [
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"
        ]

        let html = try await networkService.fetchString(from: url, headers: headers)
        let document = try SwiftSoup.parse(html)

        var items: [MediaItem] = []

        // Try to find wallpaper cards - first try article elements
        var cards = try document.select("article")
        if cards.isEmpty() {
            // Fallback: look for divs with common post class patterns
            cards = try document.select("div[class*='post']")
        }
        if cards.isEmpty() {
            // Last resort: look for any container with image and resolution pattern
            cards = try document.select("div[class*='item'], div[class*='card']")
        }

        for card in cards {
            if let item = try parseCard(card) {
                items.append(item)
            }
        }

        return items
    }

    private func parseCard(_ card: Element) throws -> MediaItem? {
        // Extract image
        guard let imgElement = try card.select("img[src*='.webp']").first() ?? card.select("img").first() else {
            return nil
        }

        guard let thumbnailURL = try imgElement.attr("src") as String?, !thumbnailURL.isEmpty else {
            return nil
        }

        let absoluteThumbnailURL = makeAbsoluteURL(thumbnailURL)
        let derivedVideoURL = deriveVideoURL(from: thumbnailURL)

        // Extract title - try multiple selectors
        var title: String?
        if let titleElement = try card.select("h2, h3, .title, [class*='title']").first() {
            title = try titleElement.text()
        }
        if title == nil || title?.isEmpty == true {
            title = try imgElement.attr("alt") as String?
        }

        guard let title = title, !title.isEmpty else {
            return nil
        }

        // Extract detail link
        guard let linkElement = try card.select("a[href]").first() else {
            return nil
        }

        guard let href = try linkElement.attr("href") as String?, !href.isEmpty else {
            return nil
        }

        let detailURL = makeAbsoluteURL(href)

        // Extract resolution - look for text pattern like "3840x2160"
        let cardText = try card.text()
        let resolutionPattern = try NSRegularExpression(pattern: "(\\d{3,4})x(\\d{3,4})", options: [])
        let resolutionMatches = resolutionPattern.matches(in: cardText, options: [], range: NSRange(cardText.startIndex..., in: cardText))

        var resolutionLabel = "HD"
        var exactResolution: String?

        if let match = resolutionMatches.first, let range = Range(match.range, in: cardText) {
            exactResolution = String(cardText[range])
            if exactResolution?.contains("3840") == true || exactResolution?.contains("4096") == true {
                resolutionLabel = "4K"
            }
        }

        // Extract creator/author - look for common patterns
        var authorName: String?
        if let authorElement = try card.select("[class*='author'], [class*='creator'], .by").first() {
            authorName = try authorElement.text()
        }
        if authorName == nil || authorName?.isEmpty == true {
            authorName = "DesktopHut"
        }

        // Create slug from title
        let slug = "desktophut_\(title.lowercased().replacingOccurrences(of: " ", with: "_").filter { $0.isLetter || $0.isNumber || $0 == "_" })"

        return MediaItem(
            slug: slug,
            title: title,
            pageURL: detailURL,
            thumbnailURL: absoluteThumbnailURL,
            resolutionLabel: resolutionLabel,
            collectionTitle: nil,
            summary: nil,
            previewVideoURL: derivedVideoURL,
            fullVideoURL: derivedVideoURL,
            posterURL: absoluteThumbnailURL,
            tags: [],
            exactResolution: exactResolution,
            sourceName: "DesktopHut",
            authorName: authorName
        )
    }

    private func makeAbsoluteURL(_ urlString: String) -> URL {
        if urlString.hasPrefix("http://") || urlString.hasPrefix("https://") {
            return URL(string: urlString) ?? URL(string: baseURL)!
        }
        if urlString.hasPrefix("/") {
            return URL(string: baseURL + urlString) ?? URL(string: baseURL)!
        }
        return URL(string: baseURL + "/" + urlString) ?? URL(string: baseURL)!
    }

    private func deriveVideoURL(from thumbnailURL: String) -> URL? {
        let pattern = #"-(\d+)\.webp$"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: thumbnailURL, range: NSRange(thumbnailURL.startIndex..., in: thumbnailURL)),
              let idRange = Range(match.range(at: 1), in: thumbnailURL) else {
            return nil
        }
        let assetID = String(thumbnailURL[idRange])
        return URL(string: "\(baseURL)/files/\(assetID).mp4")
    }
}
