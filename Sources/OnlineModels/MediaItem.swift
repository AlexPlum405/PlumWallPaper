// Sources/OnlineModels/MediaItem.swift
import Foundation

/// 在线动态媒体模型（从 MotionBG/Steam Workshop 获取）
struct MediaItem: Codable, Identifiable, Hashable {
    let id: String
    let slug: String
    let title: String
    var pageURL: URL
    let thumbnailURL: URL
    let resolutionLabel: String
    let collectionTitle: String?
    let summary: String?
    var previewVideoURL: URL?
    var fullVideoURL: URL?  // 4K 完整视频
    let posterURL: URL?
    let tags: [String]
    let exactResolution: String?
    let durationSeconds: Double?
    let downloadOptions: [MediaDownloadOption]
    let sourceName: String      // "MotionBG", "Steam Workshop"
    let isAnimatedImage: Bool?

    // Workshop-specific metadata (optional)
    let subscriptionCount: Int?
    let favoriteCount: Int?
    let viewCount: Int?
    let ratingScore: Double?
    let authorName: String?
    let fileSize: Int64?
    let createdAt: Date?
    let updatedAt: Date?

    init(
        slug: String,
        title: String,
        pageURL: URL,
        thumbnailURL: URL,
        resolutionLabel: String,
        collectionTitle: String?,
        summary: String? = nil,
        previewVideoURL: URL? = nil,
        fullVideoURL: URL? = nil,
        posterURL: URL? = nil,
        tags: [String] = [],
        exactResolution: String? = nil,
        durationSeconds: Double? = nil,
        downloadOptions: [MediaDownloadOption] = [],
        sourceName: String = "MotionBG",
        isAnimatedImage: Bool? = nil,
        subscriptionCount: Int? = nil,
        favoriteCount: Int? = nil,
        viewCount: Int? = nil,
        ratingScore: Double? = nil,
        authorName: String? = nil,
        fileSize: Int64? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = slug
        self.slug = slug
        self.title = title
        self.pageURL = pageURL
        self.thumbnailURL = thumbnailURL
        self.resolutionLabel = resolutionLabel
        self.collectionTitle = collectionTitle
        self.summary = summary
        self.previewVideoURL = previewVideoURL
        self.fullVideoURL = fullVideoURL
        self.posterURL = posterURL
        self.tags = tags
        self.exactResolution = exactResolution
        self.durationSeconds = durationSeconds
        self.downloadOptions = downloadOptions
        self.sourceName = sourceName
        self.isAnimatedImage = isAnimatedImage
        self.subscriptionCount = subscriptionCount
        self.favoriteCount = favoriteCount
        self.viewCount = viewCount
        self.ratingScore = ratingScore
        self.authorName = authorName
        self.fileSize = fileSize
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var primaryBadgeText: String {
        exactResolution ?? resolutionLabel
    }

    var secondaryBadgeText: String {
        if let durationLabel {
            return durationLabel
        }
        return downloadOptions.isEmpty ? sourceName : "\(downloadOptions.count) options"
    }

    var subtitle: String {
        if let firstTag = tags.first {
            return firstTag
        }
        if let collectionTitle, !collectionTitle.isEmpty {
            return collectionTitle
        }
        return sourceName
    }

    var durationLabel: String? {
        guard let durationSeconds else { return nil }
        let totalSeconds = Int(durationSeconds.rounded())
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

/// 下载选项
struct MediaDownloadOption: Codable, Identifiable, Hashable {
    let id: String
    let label: String           // "4K", "HD", "SD", "Workshop"
    let fileSizeLabel: String   // "890 MB"
    let detailText: String      // "3840x2160 mp4"
    let remoteURL: URL

    init(label: String, fileSizeLabel: String, detailText: String, remoteURL: URL) {
        self.label = label
        self.fileSizeLabel = fileSizeLabel
        self.detailText = detailText
        self.remoteURL = remoteURL
        self.id = "\(label.lowercased())|\(remoteURL.absoluteString)"
    }

    /// 分辨率文本（从 detailText 中提取）
    var resolutionText: String {
        let components = detailText.components(separatedBy: " ")
        return components.first ?? detailText
    }

    /// 文件大小文本
    var fileSizeText: String {
        fileSizeLabel
    }

    var qualityRank: Int {
        let normalizedLabel = label.uppercased()
        let normalizedResolution = resolutionText.uppercased()

        if normalizedLabel.contains("8K") || normalizedResolution.contains("7680") {
            return 4
        }
        if normalizedLabel.contains("4K") || normalizedResolution.contains("3840") {
            return 3
        }
        if normalizedLabel.contains("HD") || normalizedResolution.contains("1920") {
            return 2
        }
        if normalizedResolution.contains("1280") {
            return 1
        }
        return 0
    }

    var fileSizeMegabytes: Double {
        let normalized = fileSizeLabel
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: " ", with: "")

        let numericPart = normalized.replacingOccurrences(of: #"[^0-9\.]+"#, with: "", options: .regularExpression)
        guard let value = Double(numericPart) else { return 0 }

        if normalized.contains("gb") {
            return value * 1024
        }
        if normalized.contains("kb") {
            return value / 1024
        }
        return value
    }
}

/// 媒体列表页
struct MediaListPage: Equatable {
    let items: [MediaItem]
    let nextPagePath: String?
    let sectionTitle: String
}
