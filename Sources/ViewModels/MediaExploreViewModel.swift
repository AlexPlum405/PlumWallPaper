// Sources/ViewModels/MediaExploreViewModel.swift
import Foundation
import SwiftUI
import Combine

@MainActor
final class MediaExploreViewModel: ObservableObject {
    // MARK: - Published State
    @Published var mediaItems: [MediaItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasMore = true
    @Published var currentPage = 1

    // MARK: - Filters
    @Published var searchQuery = ""
    @Published var selectedSource: MediaSource = .motionBG
    @Published var selectedResolution: String? = nil
    @Published var selectedSorting = "popular"

    // MARK: - Repository
    private let repository = MediaRepository.shared

    enum MediaSource: String, CaseIterable {
        case motionBG = "MotionBG"
        case workshop = "Steam Workshop"

        var displayName: String { rawValue }
    }

    // MARK: - Public Methods

    func loadInitialData() async {
        currentPage = 1
        mediaItems = []
        hasMore = true
        await loadMore()
    }

    func loadMore() async {
        guard !isLoading && hasMore else { return }
        isLoading = true
        errorMessage = nil

        do {
            let newItems: [MediaItem]

            if !searchQuery.isEmpty {
                newItems = try await repository.search(query: searchQuery, page: currentPage)
            } else {
                // 根据选择的源和排序获取数据
                newItems = try await fetchBySource()
            }

            if newItems.isEmpty {
                hasMore = false
            } else {
                mediaItems.append(contentsOf: newItems)
                currentPage += 1
            }
        } catch {
            errorMessage = "Failed to load media: \(error.localizedDescription)"
            print("[MediaExploreViewModel] Error: \(error)")
        }

        isLoading = false
    }

    func refresh() async {
        await loadInitialData()
    }

    func applyFilters() async {
        await loadInitialData()
    }

    // MARK: - Private Methods

    private func fetchBySource() async throws -> [MediaItem] {
        switch selectedSource {
        case .motionBG:
            return try await fetchMotionBGItems()
        case .workshop:
            // TODO: Workshop service when ready
            return []
        }
    }

    private func fetchMotionBGItems() async throws -> [MediaItem] {
        // 临时禁用
        return []
    }
}
