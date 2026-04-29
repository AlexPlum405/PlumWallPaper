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

    @Relationship(deleteRule: .nullify, inverse: \Tag.wallpapers)
    var tags: [Tag]

    @Relationship(deleteRule: .cascade)
    var shaderPreset: ShaderPreset?

    init(id: UUID = UUID(), name: String, filePath: String, type: WallpaperType,
         resolution: String? = nil, fileSize: Int64 = 0, duration: Double? = nil,
         frameRate: Double? = nil, hasAudio: Bool = false, fileHash: String = "",
         thumbnailPath: String? = nil, isFavorite: Bool = false,
         volumeOverride: Int? = nil, importDate: Date = Date()) {
        self.id = id; self.name = name; self.filePath = filePath; self.type = type
        self.resolution = resolution; self.fileSize = fileSize; self.duration = duration
        self.frameRate = frameRate; self.hasAudio = hasAudio; self.fileHash = fileHash
        self.thumbnailPath = thumbnailPath; self.isFavorite = isFavorite
        self.volumeOverride = volumeOverride; self.importDate = importDate
        self.tags = []; self.shaderPreset = nil
    }
}
