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
