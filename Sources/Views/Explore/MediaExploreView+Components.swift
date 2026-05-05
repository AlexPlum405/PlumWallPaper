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
                    let isAvailable = source.isAvailable
                    FilterChip(
                        title: source.displayName,
                        isSelected: viewModel.selectedSource == source
                    ) {
                        guard isAvailable else { return }
                        withAnimation(.gallerySpring) {
                            viewModel.selectSource(source)
                        }
                        Task { await viewModel.applyFilters() }
                    }
                    .opacity(isAvailable ? 1.0 : 0.4)
                    .overlay(
                        Group {
                            if !isAvailable {
                                Text("即将推出")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundStyle(.secondary)
                                    .offset(y: 24)
                                    .allowsHitTesting(false)
                            }
                        }
                    )
                }
            }
        }
    }

    // MARK: - 排序筛选
    var sortingFilters: some View {
        artisanFilterGroup(
            title: "排序",
            options: viewModel.sortingOptionsForCurrentSource,
            selected: $viewModel.selectedSorting
        )
    }

    // MARK: - 分类筛选
    var categoryFilters: some View {
        artisanFilterGroup(
            title: "分类",
            options: viewModel.categoryFilterOptions,
            selected: $viewModel.selectedCategory
        )
    }

    // MARK: - 分辨率筛选
    var resolutionFilters: some View {
        artisanFilterGroup(
            title: "分辨率",
            options: viewModel.resolutionFilterOptions,
            selected: Binding(
                get: { viewModel.selectedResolution ?? "全部" },
                set: { viewModel.selectedResolution = $0 == "全部" ? nil : $0 }
            )
        )
    }

    // MARK: - 时长筛选
    var durationFilters: some View {
        artisanFilterGroup(
            title: "时长",
            options: viewModel.durationFilterOptions,
            selected: $viewModel.selectedDuration
        )
    }

    // MARK: - 媒体网格
    var mediaGrid: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 220, maximum: 280), spacing: 32)],
            spacing: 32
        ) {
            ForEach(viewModel.mediaItems) { item in
                MediaCard(mediaItem: item) {
                    detailWallpaper = Wallpaper.from(media: item)
                }
                .onAppear {
                    if let videoURL = item.previewVideoURL ?? item.fullVideoURL {
                        VideoPreloader.shared.preload(url: videoURL)
                    }
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
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.red.opacity(0.1))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.red.opacity(0.3), lineWidth: 0.5)
        }
    }

    // MARK: - 空状态视图
    var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 64, weight: .thin))
                .foregroundStyle(LiquidGlassColors.textQuaternary)
            
            Text("暂无媒体内容")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(LiquidGlassColors.textSecondary)
            
            Text("尝试切换数据源或调整筛选条件")
                .font(.system(size: 13))
                .foregroundStyle(LiquidGlassColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 120)
    }

    // MARK: - Artisan Filter Group
    func artisanFilterGroup(title: String, options: [String], selected: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .kerning(1.2)
                .foregroundStyle(LiquidGlassColors.textTertiary)
                .textCase(.uppercase)

            FlowLayout(spacing: 12) {
                ForEach(options, id: \.self) { option in
                    Button {
                        withAnimation(.gallerySpring) {
                            selected.wrappedValue = option
                        }
                        Task { await viewModel.applyFilters() }
                    } label: {
                        Text(option)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(selected.wrappedValue == option ? LiquidGlassColors.primaryPink : LiquidGlassColors.textSecondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .frame(minWidth: 58, minHeight: 32)
                            .background {
                                if selected.wrappedValue == option {
                                    Capsule()
                                        .fill(LiquidGlassColors.primaryPink.opacity(0.1))
                                        .overlay(Capsule().stroke(LiquidGlassColors.primaryPink.opacity(0.3), lineWidth: 0.5))
                                } else {
                                    Capsule()
                                        .fill(Color.white.opacity(0.02))
                                }
                            }
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                }
            }
        }
    }
}
