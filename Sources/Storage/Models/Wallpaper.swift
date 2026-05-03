// Sources/Storage/Models/Wallpaper.swift
import Foundation
import SwiftData

@Model
final class Wallpaper {
    var id: UUID
    var name: String
    var filePath: String
    var type: WallpaperType
    var resolution: String?
    var fileSize: Int64
    var duration: Double?
    var frameRate: Double?
    var hasAudio: Bool
    var fileHash: String
    var thumbnailPath: String?
    var isFavorite: Bool
    var volumeOverride: Int?
    var importDate: Date

    // MARK: - 在线下载支持（新增字段）
    var source: WallpaperSource
    var remoteId: String?
    var remoteSource: RemoteSourceType?
    var downloadQuality: String?
    var remoteMetadata: RemoteMetadata?

    @Relationship(deleteRule: .nullify, inverse: \Tag.wallpapers)
    var tags: [Tag]

    @Relationship(deleteRule: .cascade)
    var shaderPreset: ShaderPreset?

    init(id: UUID = UUID(), name: String, filePath: String, type: WallpaperType,
         resolution: String? = nil, fileSize: Int64 = 0, duration: Double? = nil,
         frameRate: Double? = nil, hasAudio: Bool = false, fileHash: String = "",
         thumbnailPath: String? = nil, isFavorite: Bool = false,
         volumeOverride: Int? = nil, importDate: Date = Date(),
         source: WallpaperSource = .imported, remoteId: String? = nil,
         remoteSource: RemoteSourceType? = nil, downloadQuality: String? = nil,
         remoteMetadata: RemoteMetadata? = nil) {
        self.id = id; self.name = name; self.filePath = filePath; self.type = type
        self.resolution = resolution; self.fileSize = fileSize; self.duration = duration
        self.frameRate = frameRate; self.hasAudio = hasAudio; self.fileHash = fileHash
        self.thumbnailPath = thumbnailPath; self.isFavorite = isFavorite
        self.volumeOverride = volumeOverride; self.importDate = importDate
        self.source = source; self.remoteId = remoteId; self.remoteSource = remoteSource
        self.downloadQuality = downloadQuality; self.remoteMetadata = remoteMetadata
        self.tags = []; self.shaderPreset = nil
    }
}

/// 壁纸来源
enum WallpaperSource: String, Codable {
    case online      // 在线收藏，仅保存远程引用
    case downloaded  // 从在线下载
    case imported    // 本地导入
}

/// 远程数据源类型
enum RemoteSourceType: String, Codable {
    case wallhaven
    case fourKWallpapers
    case motionBG
    case steamWorkshop
}

/// 远程壁纸元数据
struct RemoteMetadata: Codable {
    var author: String?
    var views: Int?
    var favorites: Int?
    var uploadDate: Date?
    var originalURL: String?
}

// MARK: - Conversions from Online Models
extension Wallpaper {
    /// Convert RemoteWallpaper to temporary Wallpaper for display
    static func from(remote: RemoteWallpaper) -> Wallpaper {
        return Wallpaper(
            name: remote.id,
            filePath: remote.fullImageURL?.absoluteString ?? "",
            type: .image,
            resolution: remote.resolution,
            fileSize: remote.fileSize,
            thumbnailPath: remote.thumbURL?.absoluteString,
            source: .downloaded,
            remoteId: remote.id,
            remoteSource: .wallhaven,
            remoteMetadata: RemoteMetadata(
                author: nil,
                views: remote.views,
                favorites: remote.favorites,
                uploadDate: remote.uploadedAt,
                originalURL: remote.url
            )
        )
    }

    /// Convert MediaItem to temporary Wallpaper for display
    static func from(media: MediaItem) -> Wallpaper {
        let remoteSource: RemoteSourceType = {
            switch media.sourceName.lowercased() {
            case "motionbg": return .motionBG
            case "steam workshop": return .steamWorkshop
            default: return .motionBG
            }
        }()

        return Wallpaper(
            name: media.title,
            filePath: media.hasAudioTrack == true
                ? (media.fullVideoURL?.absoluteString ?? media.previewVideoURL?.absoluteString ?? "")
                : (media.previewVideoURL?.absoluteString ?? media.fullVideoURL?.absoluteString ?? ""),
            type: .video,
            resolution: media.exactResolution ?? media.resolutionLabel,
            fileSize: media.fileSize ?? 0,
            duration: media.durationSeconds,
            thumbnailPath: media.thumbnailURL.absoluteString,
            source: .downloaded,
            remoteId: media.id,
            remoteSource: remoteSource,
            downloadQuality: media.fullVideoURL?.absoluteString,
            remoteMetadata: RemoteMetadata(
                author: media.authorName,
                views: media.viewCount,
                favorites: media.favoriteCount,
                uploadDate: media.createdAt,
                originalURL: media.pageURL.absoluteString
            )
        )
    }
}
