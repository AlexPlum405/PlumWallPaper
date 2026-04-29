// Sources/ViewModels/LibraryViewModel.swift
import Foundation
import SwiftData
import Observation

@Observable
@MainActor
final class LibraryViewModel {

    // MARK: - State

    var wallpapers: [Wallpaper] = []
    var selectedWallpaper: Wallpaper?
    var searchText: String = ""
    var isImporting: Bool = false
    var errorMessage: String?

    // MARK: - Dependencies

    private var store: WallpaperStore?

    // MARK: - Init

    func configure(modelContext: ModelContext) {
        self.store = WallpaperStore(modelContext: modelContext)
        loadWallpapers()
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
}
