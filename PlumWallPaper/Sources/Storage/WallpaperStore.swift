//
//  WallpaperStore.swift
//  PlumWallPaper
//
//  Created on 2026-04-28.
//

import Foundation
import SwiftData

/// 壁纸存储管理器
@Observable
final class WallpaperStore {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - CRUD Operations

    /// 添加壁纸
    func addWallpaper(_ wallpaper: Wallpaper) throws {
        modelContext.insert(wallpaper)
        try modelContext.save()
    }

    /// 删除壁纸
    func deleteWallpaper(_ wallpaper: Wallpaper) throws {
        modelContext.delete(wallpaper)
        try modelContext.save()
    }

    /// 更新壁纸
    func updateWallpaper() throws {
        try modelContext.save()
    }

    // MARK: - Query Operations

    /// 获取所有壁纸
    func fetchAllWallpapers() throws -> [Wallpaper] {
        let descriptor = FetchDescriptor<Wallpaper>(
            sortBy: [SortDescriptor(\.importDate, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// 获取收藏壁纸
    func fetchFavoriteWallpapers() throws -> [Wallpaper] {
        let descriptor = FetchDescriptor<Wallpaper>(
            predicate: #Predicate { $0.isFavorite },
            sortBy: [SortDescriptor(\.importDate, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// 按标签获取壁纸
    func fetchWallpapers(byTag tag: Tag) throws -> [Wallpaper] {
        let allWallpapers = try fetchAllWallpapers()
        return allWallpapers.filter { $0.tags.contains(where: { $0.id == tag.id }) }
    }

    /// 搜索壁纸
    func searchWallpapers(query: String) throws -> [Wallpaper] {
        let descriptor = FetchDescriptor<Wallpaper>(
            predicate: #Predicate { wallpaper in
                wallpaper.name.localizedStandardContains(query)
            },
            sortBy: [SortDescriptor(\.importDate, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// 检查文件哈希是否已存在（重复检测）
    func wallpaperExists(fileHash: String) throws -> Bool {
        let descriptor = FetchDescriptor<Wallpaper>(
            predicate: #Predicate { $0.fileHash == fileHash }
        )
        let results = try modelContext.fetch(descriptor)
        return !results.isEmpty
    }

    /// 获取最近使用的壁纸
    func fetchRecentWallpapers(limit: Int = 10) throws -> [Wallpaper] {
        var descriptor = FetchDescriptor<Wallpaper>(
            predicate: #Predicate { $0.lastUsedDate != nil },
            sortBy: [SortDescriptor(\.lastUsedDate, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return try modelContext.fetch(descriptor)
    }

    // MARK: - Batch Operations

    /// 批量添加壁纸
    func addWallpapers(_ wallpapers: [Wallpaper]) throws {
        for wallpaper in wallpapers {
            modelContext.insert(wallpaper)
        }
        try modelContext.save()
    }

    /// 批量删除壁纸
    func deleteWallpapers(_ wallpapers: [Wallpaper]) throws {
        for wallpaper in wallpapers {
            modelContext.delete(wallpaper)
        }
        try modelContext.save()
    }
}
