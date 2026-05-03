// Sources/ViewModels/MediaExploreViewModel.swift
import Foundation
import SwiftUI
import Combine
import AVFoundation

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
    @Published var selectedAudioTrack = AudioTrackFilter.all
    @Published var selectedSorting = "默认"

    // MARK: - Repository
    private let repository = MediaRepository.shared
    private let mediaService = MediaService.shared
    private let workshopService = WorkshopService.shared
    private let audioTrackDetector = MediaAudioTrackDetector.shared

    enum MediaSource: String, CaseIterable {
        case motionBG = "MotionBG"
        case workshop = "Steam Workshop"

        var displayName: String { rawValue }
    }

    enum AudioTrackFilter: String, CaseIterable {
        case all = "全部"
        case withAudio = "有音轨"

        var displayName: String { rawValue }
    }

    var sortingOptionsForCurrentSource: [String] {
        switch selectedSource {
        case .motionBG:
            return ["默认"]
        case .workshop:
            return ["热门", "最新", "趋势"]
        }
    }

    var showResolutionFilter: Bool {
        selectedSource == .workshop
    }

    func selectSource(_ source: MediaSource) {
        selectedSource = source
        let options = sortingOptionsForCurrentSource
        if !options.contains(selectedSorting) {
            selectedSorting = options.first ?? "默认"
        }
        if source == .motionBG {
            selectedResolution = nil
        }
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

            // 根据选择的源、搜索词和排序获取数据
            newItems = try await fetchBySource()

            if newItems.isEmpty {
                hasMore = false
            } else {
                mediaItems.append(contentsOf: newItems)
                currentPage += 1
                if selectedSource == .motionBG {
                    hasMore = false
                }
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
            return try await fetchWorkshopItems(query: searchQuery)
        }
    }

    private func fetchMotionBGItems() async throws -> [MediaItem] {
        guard currentPage == 1 else { return [] }

        let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        let items = trimmedQuery.isEmpty
            ? try await mediaService.fetchHomePage()
            : try await repository.search(query: trimmedQuery, page: currentPage)
        return await applyClientFilters(to: items)
    }

    private func fetchWorkshopItems(query: String) async throws -> [MediaItem] {
        let params = WorkshopSearchParams(
            query: query.trimmingCharacters(in: .whitespacesAndNewlines),
            sortBy: workshopSortOption,
            page: currentPage,
            pageSize: 20,
            tags: [],
            type: nil,
            contentLevel: "Everyone",
            resolution: workshopResolutionTag,
            days: workshopTrendDays
        )

        let response = try await workshopService.search(params: params)
        let items = workshopService.convertToMediaItems(response.items)
        return await applyClientFilters(to: items)
    }

    private var workshopSortOption: WorkshopSearchParams.SortOption {
        switch selectedSorting {
        case "最新":
            return .created
        case "趋势":
            return .ranked
        default:
            return .ranked
        }
    }

    private var workshopTrendDays: Int? {
        selectedSorting == "趋势" ? 7 : nil
    }

    private var workshopResolutionTag: String? {
        switch selectedResolution {
        case "4K":
            return "3840 x 2160"
        case "2K":
            return "2560 x 1440"
        case "1080P":
            return "1920 x 1080"
        default:
            return nil
        }
    }

    private func applyClientFilters(to items: [MediaItem]) async -> [MediaItem] {
        var filtered = items

        if selectedAudioTrack == .withAudio {
            filtered = await withTaskGroup(of: (Int, Bool).self) { group in
                for (index, item) in filtered.enumerated() {
                    group.addTask {
                        let hasAudio = await MediaAudioTrackDetector.shared.hasAudioTrack(in: item)
                        return (index, hasAudio)
                    }
                }

                var indexesWithAudio = Set<Int>()
                for await (index, hasAudio) in group where hasAudio {
                    indexesWithAudio.insert(index)
                }

                return filtered.enumerated()
                    .filter { indexesWithAudio.contains($0.offset) }
                    .map { $0.element.withAudioTrack(true) }
            }
        }

        return filtered
    }
}

actor MediaAudioTrackDetector {
    static let shared = MediaAudioTrackDetector()

    private var cache: [URL: Bool] = [:]

    private init() {}

    func hasAudioTrack(in item: MediaItem) async -> Bool {
        if let hasAudioTrack = item.hasAudioTrack {
            return hasAudioTrack
        }

        if item.sourceName.localizedCaseInsensitiveContains("Workshop")
            || item.sourceName.localizedCaseInsensitiveContains("Wallpaper Engine") {
            return workshopAudioHeuristic(for: item)
        }

        let candidateURLs = [item.fullVideoURL, item.previewVideoURL].compactMap { $0 }
        guard !candidateURLs.isEmpty else {
            return false
        }

        for url in candidateURLs {
            if await hasAudioTrack(at: url) {
                return true
            }
        }

        return false
    }

    func hasAudioTrack(at url: URL) async -> Bool {
        if let cached = cache[url] {
            return cached
        }

        let asset = AVURLAsset(url: url, options: [
            "AVURLAssetHTTPHeaderFieldsKey": [
                "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"
            ]
        ])

        let result = await withTaskGroup(of: Bool?.self) { group in
            group.addTask {
                do {
                    let tracks = try await asset.loadTracks(withMediaType: .audio)
                    return !tracks.isEmpty
                } catch {
                    NSLog("[MediaAudioTrackDetector] 音轨探测失败: \(url.lastPathComponent), \(error.localizedDescription)")
                    return false
                }
            }

            group.addTask {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                NSLog("[MediaAudioTrackDetector] 音轨探测超时: \(url.lastPathComponent)")
                return nil
            }

            let first = await group.next() ?? false
            group.cancelAll()
            return first ?? false
        }

        cache[url] = result
        return result
    }

    private func workshopAudioHeuristic(for item: MediaItem) -> Bool {
        let searchableText = ([item.title, item.summary ?? "", item.collectionTitle ?? ""] + item.tags)
            .joined(separator: " ")
            .lowercased()

        return ["audio", "music", "sound", "speaker", "visualizer", "音频", "音乐", "声音", "音轨"]
            .contains { searchableText.contains($0) }
    }
}
