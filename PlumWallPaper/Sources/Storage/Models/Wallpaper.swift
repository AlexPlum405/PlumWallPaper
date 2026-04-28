//
//  Wallpaper.swift
//  PlumWallPaper
//
//  Created on 2026-04-28.
//

import Foundation
import SwiftData

/// 壁纸数据模型
@Model
final class Wallpaper {
    /// 唯一标识符
    var id: UUID

    /// 壁纸名称
    var name: String

    /// 文件路径（绝对路径）
    var filePath: String

    /// 壁纸类型
    var type: WallpaperType

    /// 分辨率（如 "3840×2160"）
    var resolution: String

    /// 文件大小（字节）
    var fileSize: Int64

    /// 视频时长（秒，HEIC 为 nil）
    var duration: TimeInterval?

    /// 缩略图路径
    var thumbnailPath: String

    /// 标签
    @Relationship(deleteRule: .nullify, inverse: \Tag.wallpapers)
    var tags: [Tag]

    /// 是否收藏
    var isFavorite: Bool

    /// 导入日期
    var importDate: Date

    /// 最后使用日期
    var lastUsedDate: Date?

    /// 色彩滤镜预设
    @Relationship(deleteRule: .cascade)
    var filterPreset: FilterPreset?

    /// 文件哈希（用于重复检测）
    var fileHash: String

    /// 是否包含音频轨道
    var hasAudio: Bool?

    init(
        id: UUID = UUID(),
        name: String,
        filePath: String,
        type: WallpaperType,
        resolution: String,
        fileSize: Int64,
        duration: TimeInterval? = nil,
        thumbnailPath: String,
        tags: [Tag] = [],
        isFavorite: Bool = false,
        importDate: Date = Date(),
        lastUsedDate: Date? = nil,
        filterPreset: FilterPreset? = nil,
        fileHash: String,
        hasAudio: Bool? = nil
    ) {
        self.id = id
        self.name = name
        self.filePath = filePath
        self.type = type
        self.resolution = resolution
        self.fileSize = fileSize
        self.duration = duration
        self.thumbnailPath = thumbnailPath
        self.tags = tags
        self.isFavorite = isFavorite
        self.importDate = importDate
        self.lastUsedDate = lastUsedDate
        self.filterPreset = filterPreset
        self.fileHash = fileHash
        self.hasAudio = hasAudio
    }
}

/// 壁纸类型
enum WallpaperType: String, Codable {
    case video = "video"
    case heic = "heic"

    var displayName: String {
        switch self {
        case .video: return "视频"
        case .heic: return "HEIC"
        }
    }
}

// MARK: - Computed Properties
extension Wallpaper {
    /// 格式化的文件大小
    var formattedFileSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }

    /// 格式化的时长
    var formattedDuration: String {
        guard let duration = duration else { return "-" }
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// 是否为视频
    var isVideo: Bool {
        type == .video
    }
}
