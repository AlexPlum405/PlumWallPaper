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
    var selectedTagFilter: String? = nil
    var isImporting: Bool = false
    var errorMessage: String?

    // MARK: - Dependencies

    internal var store: WallpaperStore?

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
        isImporting = true
        Task {
            do {
                let imported = try await FileImporter.shared.importFiles(urls: urls)
                guard let store else {
                    wallpapers.append(contentsOf: imported)
                    isImporting = false
                    return
                }
                for wallpaper in imported {
                    if !wallpapers.contains(where: { $0.fileHash == wallpaper.fileHash && !$0.fileHash.isEmpty }) {
                        try store.add(wallpaper)
                    }
                }
                loadWallpapers()
                isImporting = false
            } catch {
                errorMessage = error.localizedDescription
                isImporting = false
            }
        }
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

        // 4. Apply tag filter
        if let tagFilter = selectedTagFilter {
            result = result.filter { wallpaper in
                wallpaper.tags.contains { $0.name == tagFilter }
            }
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
