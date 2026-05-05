// Sources/Storage/WallpaperStore.swift
import Foundation
import SwiftData

struct WallpaperStore {
    let modelContext: ModelContext

    func fetchAll() throws -> [Wallpaper] {
        let descriptor = FetchDescriptor<Wallpaper>(sortBy: [SortDescriptor(\.importDate, order: .reverse)])
        return try modelContext.fetch(descriptor)
    }

    /// 分页查询壁纸
    func fetchPage(offset: Int, limit: Int) throws -> [Wallpaper] {
        var descriptor = FetchDescriptor<Wallpaper>(
            sortBy: [SortDescriptor(\.importDate, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        descriptor.fetchOffset = offset
        return try modelContext.fetch(descriptor)
    }

    /// 查询壁纸总数
    func count(predicate: Predicate<Wallpaper>? = nil) throws -> Int {
        var descriptor = FetchDescriptor<Wallpaper>()
        if let predicate = predicate {
            descriptor.predicate = predicate
        }
        return try modelContext.fetchCount(descriptor)
    }

    /// 根据条件查询壁纸
    func fetch(predicate: Predicate<Wallpaper>?, sortBy: [SortDescriptor<Wallpaper>] = []) throws -> [Wallpaper] {
        var descriptor = FetchDescriptor<Wallpaper>(sortBy: sortBy)
        descriptor.predicate = predicate
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
