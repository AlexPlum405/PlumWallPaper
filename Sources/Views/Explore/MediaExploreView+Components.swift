import SwiftUI

// MARK: - MediaExploreView Components
extension MediaExploreView {

    // MARK: - 搜索栏
    var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(LiquidGlassColors.textSecondary)

            TextField("搜索动态壁纸...", text: $viewModel.searchQuery)
                .textFieldStyle(.plain)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(LiquidGlassColors.textPrimary)
                .onSubmit {
                    Task { await viewModel.applyFilters() }
                }

            if !viewModel.searchQuery.isEmpty {
                Button {
                    viewModel.searchQuery = ""
                    Task { await viewModel.applyFilters() }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(LiquidGlassColors.textSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 18)
        .frame(height: 44)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(LiquidGlassColors.surfaceBackground.opacity(0.6))
                .background(.ultraThinMaterial)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(LiquidGlassColors.glassBorder, lineWidth: 0.5)
        }
    }

    // MARK: - 来源筛选
    var sourceFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(MediaExploreViewModel.MediaSource.allCases, id: \.self) { source in
                    FilterChip(
                        title: source.displayName,
                        isSelected: viewModel.selectedSource == source
                    ) {
                        withAnimation(.gallerySpring) {
                            viewModel.selectedSource = source
                        }
                        Task { await viewModel.applyFilters() }
                    }
                }
            }
        }
    }

    // MARK: - 分辨率筛选
    var resolutionFilters: some View {
        artisanFilterGroup(
            title: "分辨率",
            options: resolutionOptions,
            selected: Binding(
                get: { viewModel.selectedResolution ?? "全部" },
                set: { viewModel.selectedResolution = $0 == "全部" ? nil : $0 }
            )
        )
    }

    // MARK: - 排序筛选
    var sortingFilters: some View {
        artisanFilterGroup(
            title: "排序",
            options: sortingOptions,
            selected: $viewModel.selectedSorting
        )
    }

    // MARK: - 高级筛选按钮
    var advancedFiltersButton: some View {
        Button {
            withAnimation(.gallerySpring) {
                showFilters.toggle()
            }
        } label: {
            HStack(spacing: 8) {
                Text("高级筛选")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(LiquidGlassColors.textSecondary)
                Image(systemName: showFilters ? "chevron.up" : "chevron.down")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(LiquidGlassColors.textTertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(LiquidGlassColors.surfaceBackground.opacity(0.4))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(LiquidGlassColors.glassBorder, lineWidth: 0.5)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - 高级筛选区域
    var advancedFiltersSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Divider()
                .background(LiquidGlassColors.glassBorder)
            
            HStack(spacing: 32) {
                resolutionFilters
                Spacer()
            }
        }
        .padding(.top, 8)
    }

    // MARK: - 媒体网格
    var mediaGrid: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 220, maximum: 280), spacing: 32)],
            spacing: 32
        ) {
            ForEach(viewModel.mediaItems) { item in
                MediaCard(mediaItem: item) {
                    detailMedia = item
                }
            }
            
            // 加载更多指示器
            if viewModel.hasMore && !viewModel.mediaItems.isEmpty {
                loadingIndicator
            }
        }
    }

    // MARK: - 加载指示器
    var loadingIndicator: some View {
        VStack(spacing: 16) {
            CustomProgressView(tint: LiquidGlassColors.primaryPink, scale: 1.2)
            Text("Loading more media...")
                .font(.custom("Georgia", size: 12).italic())
                .foregroundStyle(LiquidGlassColors.textQuaternary)
        }
        .padding(.vertical, 60)
        .frame(maxWidth: .infinity)
        .onAppear {
            Task {
                await viewModel.loadMore()
            }
        }
    }

    // MARK: - 错误横幅
    func errorBanner(_ message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 16))
                .foregroundStyle(.red)
            
            Text(message)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(LiquidGlassColors.textPrimary)
            
            Spacer()
            
            Button {
                Task {
                    await viewModel.refresh()
                }
            } label: {
                Text("重试")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(LiquidGlassColors.primaryPink)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.red.opacity(0.1))
                .background(.ultraThinMaterial)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        }
    }

    // MARK: - 空状态视图
    var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "film.stack")
                .font(.system(size: 64, weight: .thin))
                .foregroundStyle(LiquidGlassColors.textQuaternary)
            
            VStack(spacing: 8) {
                Text("暂无媒体内容")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(LiquidGlassColors.textPrimary)
                
                Text("尝试调整筛选条件或稍后再试")
                    .font(.system(size: 13))
                    .foregroundStyle(LiquidGlassColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 120)
    }

    // MARK: - Helper: Filter Group
    func artisanFilterGroup(title: String, options: [String], selected: Binding<String>) -> some View {
        HStack(spacing: 14) {
            Text(title)
                .font(.system(size: 11, weight: .black))
                .kerning(1.5)
                .foregroundStyle(LiquidGlassColors.textQuaternary)
            
            HStack(spacing: 8) {
                ForEach(options, id: \.self) { option in
                    FilterChip(
                        title: option,
                        isSelected: selected.wrappedValue == option
                    ) {
                        withAnimation(.gallerySpring) {
                            selected.wrappedValue = option
                        }
                        Task {
                            await viewModel.applyFilters()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Filter Options Data
    var resolutionOptions: [String] {
        ["全部", "4K", "2K", "1080P"]
    }

    var sortingOptions: [String] {
        ["popular", "latest", "trending"]
    }
}
