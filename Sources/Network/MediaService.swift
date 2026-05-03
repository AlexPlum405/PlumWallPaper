// Sources/Network/MediaService.swift
import Foundation
import SwiftSoup

/// 媒体服务 - 解析 MotionBG 网站
actor MediaService {
    static let shared = MediaService()

    private let networkService = NetworkService.shared
    private let baseURL = URL(string: "https://motionbgs.com")!

    private init() {}

    // MARK: - Public API

    func fetchHomePage() async throws -> [MediaItem] {
        NSLog("[MediaService] fetchHomePage() 开始")

        let html = try await networkService.fetchString(
            from: baseURL,
            headers: [
                "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36",
                "Accept-Language": "en-US,en;q=0.9"
            ]
        )

        NSLog("[MediaService] HTML 获取成功，长度: \(html.count)")

        return try parseHomePage(html: html)
    }

    func search(query: String) async throws -> [MediaItem] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return try await fetchHomePage() }

        var components = URLComponents(url: baseURL.appendingPathComponent("search"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "q", value: trimmed)]
        guard let url = components?.url else { throw NetworkError.invalidResponse }

        let html = try await networkService.fetchString(
            from: url,
            headers: [
                "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36",
                "Accept-Language": "en-US,en;q=0.9"
            ]
        )

        return try parseHomePage(html: html)
    }

    func fetchDetail(slug: String) async throws -> MediaItem {
        let trimmed = slug.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard !trimmed.isEmpty else { throw NetworkError.invalidResponse }

        let url = baseURL.appendingPathComponent(trimmed)
        let html = try await networkService.fetchString(
            from: url,
            headers: [
                "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36",
                "Accept-Language": "en-US,en;q=0.9"
            ]
        )

        return try parseDetailPage(html: html, slug: trimmed, pageURL: url)
    }

    // MARK: - HTML Parsing

    private func parseHomePage(html: String) throws -> [MediaItem] {
        let document = try SwiftSoup.parse(html)

        // 使用正确的选择器：a[title*='live wallpaper']
        let elements = try document.select("a[title*='live wallpaper']")

        NSLog("[MediaService] 找到 \(elements.count) 个元素")

        var items: [MediaItem] = []
        var seen = Set<String>()

        for element in elements {
            // 提取标题
            guard let title = try? element.attr("title"),
                  !title.isEmpty else {
                continue
            }

            // 提取链接
            guard let href = try? element.attr("href"),
                  !href.isEmpty else {
                continue
            }

            // 从 href 提取 slug
            let slug = href.replacingOccurrences(of: "/", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard !slug.isEmpty, seen.insert(slug).inserted else {
                continue
            }

            // 清理标题（移除 "live wallpaper"）
            let cleanTitle = title.replacingOccurrences(of: " live wallpaper", with: "", options: [.caseInsensitive])

            // 尝试提取图片和视频 URL
            var thumbnailURL: URL?
            var previewVideoURL: URL?
            var fullVideoURL: URL?

            // 1. 优先从 picture > source 的 srcset 提取文件名，然后构建 4K 图片和预览视频 URL
            if let picture = try? element.select("picture").first() {
                if let source = try? picture.select("source").first(),
                   let srcset = try? source.attr("srcset"),
                   !srcset.isEmpty {
                    // srcset 格式: /i/c/546x308/media/9403/angel-bound-by-thorns.3840x2160.jpg.webp
                    // 我们需要提取: media/9403/angel-bound-by-thorns
                    let srcURL = srcset.components(separatedBy: " ").first ?? srcset

                    // 从路径中提取 media/ID/filename
                    if let mediaRange = srcURL.range(of: "media/\\d+/[^/]+", options: .regularExpression) {
                        let mediaPath = String(srcURL[mediaRange])
                        // 移除 .webp 和分辨率后缀
                        let cleanPath = mediaPath
                            .replacingOccurrences(of: ".webp", with: "")
                            .replacingOccurrences(of: ".3840x2160.jpg", with: "")
                            .replacingOccurrences(of: ".jpg", with: "")

                        // 构建 4K 图片 URL
                        thumbnailURL = baseURL.appendingPathComponent(cleanPath + ".3840x2160.jpg")

                        // 构建预览视频 URL - 使用 1080p 以平衡质量和性能
                        previewVideoURL = baseURL.appendingPathComponent(cleanPath + ".1920x1080.mp4")

                        // 构建完整 4K 视频 URL
                        fullVideoURL = baseURL.appendingPathComponent(cleanPath + ".3840x2160.mp4")

                        NSLog("[MediaService] 构建 4K 图片: \(thumbnailURL?.absoluteString ?? "nil")")
                        NSLog("[MediaService] 构建 1080p 视频: \(previewVideoURL?.absoluteString ?? "nil")")
                        NSLog("[MediaService] 构建 4K 视频: \(fullVideoURL?.absoluteString ?? "nil")")
                    }
                }
            }

            // 2. 回退到 img 标签
            if thumbnailURL == nil {
                if let img = try? element.select("img").first(),
                   let src = try? img.attr("src") {
                    if src.hasPrefix("http") {
                        thumbnailURL = URL(string: src)
                    } else if src.hasPrefix("/") {
                        thumbnailURL = baseURL.appendingPathComponent(src)
                    } else {
                        thumbnailURL = baseURL.appendingPathComponent("/\(src)")
                    }
                }
            }

            let item = MediaItem(
                slug: slug,
                title: cleanTitle,
                pageURL: baseURL.appendingPathComponent(href),
                thumbnailURL: thumbnailURL ?? baseURL,
                resolutionLabel: "4K",
                collectionTitle: nil,
                summary: nil,
                previewVideoURL: previewVideoURL,
                fullVideoURL: fullVideoURL,
                posterURL: thumbnailURL,
                tags: [],
                exactResolution: "3840x2160",
                durationSeconds: nil,
                downloadOptions: [],
                sourceName: "MotionBG",
                isAnimatedImage: false,
                subscriptionCount: nil,
                favoriteCount: nil,
                viewCount: nil,
                ratingScore: nil,
                authorName: nil,
                fileSize: nil,
                createdAt: nil,
                updatedAt: nil
            )

            items.append(item)
        }

        NSLog("[MediaService] 解析完成，获得 \(items.count) 个项目")

        return items
    }

    private func parseDetailPage(html: String, slug: String, pageURL: URL) throws -> MediaItem {
        let document = try SwiftSoup.parse(html)

        let title = cleanTitle(
            (try? document.select("meta[property='og:title']").first()?.attr("content"))
            ?? (try? document.select("title").first()?.text())
            ?? slug
        )

        let posterString = (try? document.select("meta[property='og:image']").first()?.attr("content"))
            ?? (try? document.select("video[poster]").first()?.attr("poster"))
            ?? (try? document.select("picture source[srcset]").first()?.attr("srcset").components(separatedBy: " ").first)

        guard let posterString,
              let thumbnailURL = URL(string: posterString, relativeTo: baseURL)?.absoluteURL else {
            throw NetworkError.invalidResponse
        }

        let previewURL = (
            (try? document.select("meta[property='og:video']").first()?.attr("content"))
            ?? (try? document.select("video source[src]").first()?.attr("src"))
        ).flatMap { URL(string: $0, relativeTo: baseURL)?.absoluteURL }

        let tags = ((try? document.select("a[href^='/tag:']").array()) ?? [])
            .compactMap { try? $0.text().trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .uniqued()

        let summary = (try? document.select("meta[name='description']").first()?.attr("content"))?.htmlDecoded
        let downloadOptions = parseDownloadOptions(html: html)
        let bestDownload = downloadOptions.sorted { $0.qualityRank > $1.qualityRank }.first
        let durationSeconds = parseDurationSeconds(html: html)

        return MediaItem(
            slug: slug,
            title: title,
            pageURL: pageURL,
            thumbnailURL: thumbnailURL,
            resolutionLabel: bestDownload?.label ?? "Live",
            collectionTitle: tags.first,
            summary: summary,
            previewVideoURL: previewURL,
            fullVideoURL: bestDownload?.remoteURL ?? previewURL,
            posterURL: thumbnailURL,
            tags: tags,
            exactResolution: bestDownload?.resolutionText,
            durationSeconds: durationSeconds,
            downloadOptions: downloadOptions,
            sourceName: "MotionBG",
            isAnimatedImage: false,
            subscriptionCount: nil,
            favoriteCount: nil,
            viewCount: nil,
            ratingScore: nil,
            authorName: nil,
            fileSize: nil,
            createdAt: nil,
            updatedAt: nil
        )
    }

    private func parseDownloadOptions(html: String) -> [MediaDownloadOption] {
        let pattern = #"href=["']?(/dl/\w+/\d+)["']?[\s\S]*?font-bold[^>]*>(\w+)</span>[\s\S]*?\(([^)]+)\)[\s\S]*?text-xs[^>]*>([^<]+)</div>"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) else {
            return []
        }

        let range = NSRange(html.startIndex..., in: html)
        return regex.matches(in: html, options: [], range: range).compactMap { match in
            guard
                let href = capture(match: match, in: html, at: 1),
                let label = capture(match: match, in: html, at: 2)?.htmlDecoded,
                let fileSize = capture(match: match, in: html, at: 3)?.htmlDecoded,
                let detailText = capture(match: match, in: html, at: 4)?.htmlDecoded,
                let url = URL(string: href, relativeTo: baseURL)?.absoluteURL
            else {
                return nil
            }

            return MediaDownloadOption(
                label: label.trimmingCharacters(in: .whitespacesAndNewlines),
                fileSizeLabel: fileSize.trimmingCharacters(in: .whitespacesAndNewlines),
                detailText: detailText.trimmingCharacters(in: .whitespacesAndNewlines),
                remoteURL: url
            )
        }
    }

    private func parseDurationSeconds(html: String) -> Double? {
        guard let raw = captureFirst(in: html, pattern: #""duration"\s*:\s*"PT([0-9HM.S]+)""#) else {
            return nil
        }

        if raw.hasSuffix("S"), let seconds = Double(raw.dropLast()) {
            return seconds
        }

        let parts = raw.components(separatedBy: "M")
        if parts.count == 2,
           let minutes = Double(parts[0].replacingOccurrences(of: "H", with: "")),
           let seconds = Double(parts[1].replacingOccurrences(of: "S", with: "")) {
            return minutes * 60 + seconds
        }

        return nil
    }

    private func cleanTitle(_ value: String) -> String {
        value
            .replacingOccurrences(of: " live wallpaper", with: "", options: [.caseInsensitive])
            .replacingOccurrences(of: " - MotionBGs", with: "", options: [.caseInsensitive])
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .htmlDecoded
    }

    private func capture(match: NSTextCheckingResult, in text: String, at index: Int) -> String? {
        guard let range = Range(match.range(at: index), in: text) else { return nil }
        return String(text[range])
    }

    private func captureFirst(in text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) else {
            return nil
        }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range) else { return nil }
        return capture(match: match, in: text, at: 1)
    }
}

private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}

private extension String {
    var htmlDecoded: String {
        let entities: [String: String] = [
            "&amp;": "&",
            "&lt;": "<",
            "&gt;": ">",
            "&quot;": "\"",
            "&#39;": "'",
            "&apos;": "'",
            "&nbsp;": " "
        ]

        return entities.reduce(self) { partial, item in
            partial.replacingOccurrences(of: item.key, with: item.value)
        }
    }
}
