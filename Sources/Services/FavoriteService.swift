import Foundation
import SwiftData

enum FavoriteService {
    static func toggleFavorite(for wallpaper: Wallpaper, in modelContext: ModelContext) throws -> Bool {
        if let persisted = try persistedWallpaper(for: wallpaper, in: modelContext) {
            if persisted.isFavorite && persisted.source == .online {
                modelContext.delete(persisted)
                try modelContext.save()
                return false
            }

            persisted.isFavorite.toggle()
            try modelContext.save()
            return persisted.isFavorite
        }

        modelContext.insert(makeOnlineFavoriteCopy(from: wallpaper))
        try modelContext.save()
        return true
    }

    static func persistedWallpaper(for wallpaper: Wallpaper, in modelContext: ModelContext) throws -> Wallpaper? {
        let wallpaperId = wallpaper.id
        let idDescriptor = FetchDescriptor<Wallpaper>(
            predicate: #Predicate<Wallpaper> { $0.id == wallpaperId }
        )
        if let exactMatch = try modelContext.fetch(idDescriptor).first {
            return exactMatch
        }

        guard let remoteId = wallpaper.remoteId else { return nil }
        let remoteDescriptor = FetchDescriptor<Wallpaper>(
            predicate: #Predicate<Wallpaper> { $0.remoteId == remoteId },
            sortBy: [SortDescriptor(\.importDate, order: .reverse)]
        )
        return try modelContext.fetch(remoteDescriptor).first
    }

    private static func makeOnlineFavoriteCopy(from wallpaper: Wallpaper) -> Wallpaper {
        Wallpaper(
            name: wallpaper.name,
            filePath: wallpaper.filePath,
            type: wallpaper.type,
            resolution: wallpaper.resolution,
            fileSize: wallpaper.fileSize,
            duration: wallpaper.duration,
            frameRate: wallpaper.frameRate,
            hasAudio: wallpaper.hasAudio,
            thumbnailPath: wallpaper.thumbnailPath,
            isFavorite: true,
            source: .online,
            remoteId: wallpaper.remoteId,
            remoteSource: wallpaper.remoteSource,
            downloadQuality: wallpaper.downloadQuality,
            remoteMetadata: wallpaper.remoteMetadata
        )
    }
}
