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
}
