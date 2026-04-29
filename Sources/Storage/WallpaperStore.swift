// Sources/Storage/WallpaperStore.swift
import Foundation
import SwiftData

struct WallpaperStore {
    let modelContext: ModelContext

    func fetchAll() throws -> [Wallpaper] {
        let descriptor = FetchDescriptor<Wallpaper>(sortBy: [SortDescriptor(\.importDate, order: .reverse)])
        return try modelContext.fetch(descriptor)
    }

    func add(_ wallpaper: Wallpaper) throws {
        modelContext.insert(wallpaper)
        try modelContext.save()
    }

    func delete(_ wallpaper: Wallpaper) throws {
        modelContext.delete(wallpaper)
        try modelContext.save()
    }

    func fetchByHash(_ hash: String) throws -> Wallpaper? {
        let descriptor = FetchDescriptor<Wallpaper>(predicate: #Predicate { $0.fileHash == hash })
        return try modelContext.fetch(descriptor).first
    }
}
