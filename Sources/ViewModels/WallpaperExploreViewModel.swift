// Sources/ViewModels/WallpaperExploreViewModel.swift
import Foundation
import SwiftUI
import Combine

@MainActor
final class WallpaperExploreViewModel: ObservableObject {
    // MARK: - Published State
    @Published var wallpapers: [RemoteWallpaper] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasMore = true
    @Published var currentPage = 1

    // MARK: - Filters
    @Published var searchQuery = ""
    @Published var selectedCategory = "111"  // general, anime, people
    @Published var selectedPurity = "100"    // sfw only by default
    @Published var selectedSorting = "date_added"
    @Published var selectedOrder = "desc"
    @Published var selectedTopRange: String? = nil
    @Published var selectedResolutions: [String] = []
    @Published var selectedRatios: [String] = []
    @Published var selectedColors: [String] = []

    // MARK: - Repository
    private let repository = WallpaperRepository.shared

    // MARK: - Public Methods

    func loadInitialData() async {
        currentPage = 1
        wallpapers = []
        hasMore = true
        await loadMore()
    }

    func loadMore() async {
        guard !isLoading && hasMore else { return }
        isLoading = true
        errorMessage = nil

        do {
            let newWallpapers = try await repository.search(
                query: searchQuery,
                page: currentPage,
                categories: selectedCategory,
                purity: selectedPurity,
                sorting: selectedSorting,
                order: selectedOrder,
                topRange: selectedTopRange,
                resolutions: selectedResolutions,
                ratios: selectedRatios,
                colors: selectedColors
            )

            if newWallpapers.isEmpty {
                hasMore = false
            } else {
                wallpapers.append(contentsOf: newWallpapers)
                currentPage += 1
            }
        } catch {
            errorMessage = "Failed to load wallpapers: \(error.localizedDescription)"
            print("[WallpaperExploreViewModel] Error: \(error)")
        }

        isLoading = false
    }

    func refresh() async {
        await loadInitialData()
    }

    func applyFilters() async {
        await loadInitialData()
    }
}
