// Sources/ViewModels/LibraryViewModel.swift
import Foundation
import SwiftData
import Observation

@Observable
@MainActor
final class LibraryViewModel {

    // MARK: - SubTabs
    enum LibraryTab: String, CaseIterable {
        case favorites = "收藏"
        case downloads = "下载"
        case history = "历史记录"
    }

    // MARK: - State

    var selectedTab: LibraryTab = .favorites
    var wallpapers: [Wallpaper] = []
    var selectedWallpaper: Wallpaper?
    var searchText: String = ""
    var isImporting: Bool = false
    var errorMessage: String?

    // MARK: - Dependencies

    private var store: WallpaperStore?

    // MARK: - Init

    init() {
        // 初始 Mock 数据，确保符合 Wallpaper 初始化规范 (必需 filePath)
        self.wallpapers = [
            Wallpaper(name: "霓虹雨夜", filePath: "", type: .video, resolution: "4K", thumbnailPath: "", isFavorite: true),
            Wallpaper(name: "赛博之城", filePath: "", type: .image, resolution: "8K", thumbnailPath: "", isFavorite: true),
            Wallpaper(name: "寂静森林", filePath: "", type: .video, resolution: "4K", thumbnailPath: "", isFavorite: false),
            Wallpaper(name: "极光边缘", filePath: "", type: .heic, resolution: "5K", thumbnailPath: "", isFavorite: true),
            Wallpaper(name: "数字海洋", filePath: "", type: .video, resolution: "4K", thumbnailPath: "", isFavorite: false),
            Wallpaper(name: "量子脉冲", filePath: "", type: .image, resolution: "4K", thumbnailPath: "", isFavorite: true)
        ]
    }

    func configure(modelContext: ModelContext) {
        self.store = WallpaperStore(modelContext: modelContext)
        // loadWallpapers() // 先保留 Mock，不覆盖
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
        guard !searchText.isEmpty else { return wallpapers }
        return wallpapers.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
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
