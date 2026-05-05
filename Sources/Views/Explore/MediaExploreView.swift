import SwiftUI

// MARK: - Artisan Media Explore (Scheme C: Pure Edition)
struct MediaExploreView: View {
    @StateObject var viewModel = MediaExploreViewModel()
    @State var detailItem: WallpaperPreviewItem?
    @State var showFilters = false
    @State private var scrollOffset: CGFloat = 0

    let mainPadding: CGFloat = 88

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 48) {
                // 1. 顶部筛选区域
                artisanFilterSection
                    .padding(.top, 100) // 避开 TabBar

                // 2. 错误提示
                if let errorMessage = viewModel.errorMessage {
                    errorBanner(errorMessage)
                }

                // 3. 媒体网格
                if viewModel.mediaItems.isEmpty && !viewModel.isLoading {
                    emptyStateView
                } else {
                    mediaGrid
                }
            }
            .padding(.horizontal, mainPadding)
            .padding(.bottom, 100)
        }
        .background(LiquidGlassColors.deepBackground)
        .sheet(item: $detailItem) { item in
            WallpaperDetailView(
                wallpaper: item.makeWallpaper(),
                onPrevious: { current, callback in
                    let newWallpaper = getNavigateWallpaper(current: current, direction: -1)
                    callback(newWallpaper)
                },
                onNext: { current, callback in
                    let newWallpaper = getNavigateWallpaper(current: current, direction: 1)
                    callback(newWallpaper)
                }
            )
        }
        .onAppear {
            NSLog("[MediaExploreView] .onAppear 被调用")
            if viewModel.mediaItems.isEmpty {
                Task {
                    NSLog("[MediaExploreView] 开始加载初始数据")
                    await viewModel.loadInitialData()
                    preheatVisibleMediaVideos()
                }
            } else {
                preheatVisibleMediaVideos()
            }
        }
        .onChange(of: viewModel.mediaItems) { _, _ in
            preheatVisibleMediaVideos()
        }
    }

    private func preheatVisibleMediaVideos() {
        PreviewResourcePipeline.shared.preloadPreviewVideos(for: viewModel.mediaItems, limit: 8)
    }

    // MARK: - Navigation Logic
    private func getNavigateWallpaper(current: Wallpaper? = nil, direction: Int) -> Wallpaper {
        let allItems = viewModel.mediaItems.map(WallpaperPreviewItem.init(media:))
        let activeRemoteId = current?.remoteId ?? detailItem?.remoteId
        let activeTitle = current?.name ?? detailItem?.title

        guard !allItems.isEmpty else {
            return current ?? detailItem?.makeWallpaper() ?? Wallpaper(name: "Unknown", filePath: "", type: .video)
        }

        if let currentIndex = allItems.firstIndex(where: { $0.remoteId == activeRemoteId || $0.title == activeTitle }) {
            let newIndex = (currentIndex + direction + allItems.count) % allItems.count
            return allItems[newIndex].makeWallpaper()
        }

        return allItems.first?.makeWallpaper() ?? Wallpaper(name: "Unknown", filePath: "", type: .video)
    }

    // MARK: - 筛选区域
    private var artisanFilterSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            // 搜索栏
            searchBar

            // 来源筛选
            sourceFilters

            // API Key 提示（未配置或配置后加载失败时显示）
            if let keyService = viewModel.selectedSource.apiKeyService,
               !APIKeyManager.shared.hasKey(for: keyService) {
                APIKeyInputBanner(service: keyService) {
                    Task { await viewModel.applyFilters() }
                }
            }

            // 筛选和排序
            VStack(alignment: .leading, spacing: 20) {
                if viewModel.categoryFilterOptions.count > 1 {
                    categoryFilters
                }
                if viewModel.sortingOptionsForCurrentSource.count > 1 {
                    sortingFilters
                }
                if viewModel.resolutionFilterOptions.count > 1 {
                    resolutionFilters
                }
                if viewModel.durationFilterOptions.count > 1 {
                    durationFilters
                }
            }
        }
    }
}
