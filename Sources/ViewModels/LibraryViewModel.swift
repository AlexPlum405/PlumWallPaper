// Sources/ViewModels/LibraryViewModel.swift
import Foundation
import SwiftData
import Observation

@Observable
@MainActor
final class LibraryViewModel {

    // MARK: - Filter Enums
    enum WallpaperTypeFilter: String, CaseIterable {
        case all = "全部"
        case image = "静态"
        case video = "动态"
    }

    enum WallpaperSourceFilter: String, CaseIterable {
        case favorites = "收藏"
        case downloaded = "下载"
        case imported = "导入"
    }

    // MARK: - SubTabs (Deprecated - kept for compatibility)
    enum LibraryTab: String, CaseIterable {
        case favorites = "收藏"
        case downloads = "下载"
        case history = "历史记录"
    }

    // MARK: - State

    var selectedTab: LibraryTab = .favorites
    var typeFilter: WallpaperTypeFilter = .all
    var sourceFilter: WallpaperSourceFilter = .favorites
    var wallpapers: [Wallpaper] = []
    var selectedWallpaper: Wallpaper?
    var searchText: String = ""
    var isImporting: Bool = false
    var errorMessage: String?

    // MARK: - Dependencies

    private var store: WallpaperStore?

    // MARK: - Init

    init() {
        // 初始化为空数组，等待从数据库加载
        self.wallpapers = []
    }

    func configure(modelContext: ModelContext) {
        self.store = WallpaperStore(modelContext: modelContext)
        loadWallpapers() // 从数据库加载真实数据
    }

    // MARK: - Actions

    func loadWallpapers() {
        guard let store else { return }
        do {
            wallpapers = try store.fetchAll()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteWallpaper(_ wallpaper: Wallpaper) {
        guard let store else { return }
        do {
            try store.delete(wallpaper)
            if selectedWallpaper?.id == wallpaper.id {
                selectedWallpaper = nil
            }
            loadWallpapers()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleFavorite(_ wallpaper: Wallpaper) {
        wallpaper.isFavorite.toggle()
        do {
            try store?.modelContext.save()
            loadWallpapers()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func importFiles(urls: [URL]) {
        // Skeleton: real import logic will be added in a later task
        isImporting = true
        defer { isImporting = false }
        // TODO: call import pipeline
    }

    var filteredWallpapers: [Wallpaper] {
        var result = wallpapers

        // 1. Apply type filter
        switch typeFilter {
        case .all:
            break
        case .image:
            result = result.filter { $0.type == .image || $0.type == .heic }
        case .video:
            result = result.filter { $0.type == .video }
        }

        // 2. Apply source filter
        switch sourceFilter {
        case .favorites:
            result = result.filter { $0.isFavorite }
        case .downloaded:
            result = result.filter { $0.source == .downloaded }
        case .imported:
            result = result.filter { $0.source == .imported }
        }

        // 3. Apply search filter
        if !searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }

        return result
    }

    // MARK: - Batch Operations

    func save() {
        guard let store else { return }
        do {
            try store.modelContext.save()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
