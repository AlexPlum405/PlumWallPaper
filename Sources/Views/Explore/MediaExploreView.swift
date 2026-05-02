import SwiftUI

// MARK: - Artisan Media Explore (Scheme C: Pure Edition)
struct MediaExploreView: View {
    @StateObject var viewModel = MediaExploreViewModel()
    @State var detailMedia: MediaItem?
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
        .sheet(item: $detailMedia) { media in
            MediaDetailView(mediaItem: media)
        }
        .onAppear {
            NSLog("[MediaExploreView] .onAppear 被调用")
            if viewModel.mediaItems.isEmpty {
                Task {
                    NSLog("[MediaExploreView] 开始加载初始数据")
                    await viewModel.loadInitialData()
                }
            }
        }
    }

    // MARK: - 筛选区域
    private var artisanFilterSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            // 搜索栏
            searchBar

            // 来源筛选
            sourceFilters

            // 高级筛选按钮和选项
            HStack(spacing: 32) {
                sortingFilters
                Spacer()
                advancedFiltersButton
            }

            // 展开的高级筛选
            if showFilters {
                advancedFiltersSection
            }
        }
    }
}

