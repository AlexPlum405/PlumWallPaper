import SwiftUI

// MARK: - Artisan Wallpaper Explore (Scheme C: Pure Edition)
struct WallpaperExploreView: View {
    @StateObject private var viewModel = WallpaperExploreViewModel()
    @State private var detailWallpaper: Wallpaper?
    @State private var showFilters = false

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

                // 3. 瀑布流画卷
                if viewModel.wallpapers.isEmpty && !viewModel.isLoading {
                    emptyStateView
                } else {
                    wallpaperGrid
                }
            }
            .padding(.horizontal, mainPadding)
            .padding(.bottom, 100)
        }
        .background(LiquidGlassColors.deepBackground)
        .sheet(item: $detailWallpaper) { wallpaper in
            WallpaperDetailView(
                wallpaper: wallpaper,
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
            NSLog("[WallpaperExploreView] .onAppear 被调用")
            if viewModel.wallpapers.isEmpty {
                Task {
                    NSLog("[WallpaperExploreView] 开始加载初始数据")
                    await viewModel.loadInitialData()
                }
            }
        }
    }

    // MARK: - Navigation Logic
    private func getNavigateWallpaper(current: Wallpaper? = nil, direction: Int) -> Wallpaper {
        let allWallpapers = viewModel.wallpapers.map(Wallpaper.from)
        let activeWallpaper = current ?? detailWallpaper

        guard !allWallpapers.isEmpty else {
            return activeWallpaper ?? Wallpaper(name: "Unknown", filePath: "", type: .image)
        }

        if let activeWallpaper,
           let currentIndex = allWallpapers.firstIndex(where: { $0.remoteId == activeWallpaper.remoteId || $0.name == activeWallpaper.name }) {
            let newIndex = (currentIndex + direction + allWallpapers.count) % allWallpapers.count
            return allWallpapers[newIndex]
        }

        return allWallpapers.first ?? Wallpaper(name: "Unknown", filePath: "", type: .image)
    }

    // MARK: - 筛选区域
    private var artisanFilterSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            // 搜索栏
            if viewModel.selectedSource.supportsSearch {
                searchBar
            }

            // 来源筛选
            sourceFilters

            // Wallhaven 专属筛选（分类、纯度、排序）
            if viewModel.showWallhavenFilters {
                // 分类筛选
                categoryFilters

                // 高级筛选按钮和选项
                VStack(alignment: .leading, spacing: 20) {
                    purityFilters
                    sortingFilters
                    HStack {
                        Spacer()
                        advancedFiltersButton
                    }
                }

                // 展开的高级筛选
                if showFilters {
                    advancedFiltersSection
                }
            } else {
                // 其他源的源定制筛选
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
                }
            }

            // API Key 提示（未配置或配置后加载失败时显示）
            if let keyService = viewModel.selectedSource.apiKeyService,
               !APIKeyManager.shared.hasKey(for: keyService) {
                APIKeyInputBanner(service: keyService) {
                    Task { await viewModel.applyFilters() }
                }
            }
        }
    }

    // MARK: - 来源筛选
    private var sourceFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(WallpaperExploreViewModel.WallpaperSource.allCases, id: \.self) { source in
                    FilterChip(
                        title: source.displayName,
                        isSelected: viewModel.selectedSource == source
                    ) {
                        withAnimation(.gallerySpring) {
                            viewModel.selectSource(source)
                        }
                        Task { await viewModel.applyFilters() }
                    }
                }
            }
        }
    }

    // MARK: - 搜索栏
    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(LiquidGlassColors.textSecondary)

            TextField("搜索壁纸...", text: $viewModel.searchQuery)
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

    // MARK: - 分类筛选
    private var categoryFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(viewModel.categoryFilterOptions, id: \.value) { category in
                    FilterChip(
                        title: category.label,
                        isSelected: viewModel.selectedCategory == category.value
                    ) {
                        withAnimation(.gallerySpring) {
                            viewModel.selectedCategory = category.value
                        }
                        Task { await viewModel.applyFilters() }
                    }
                }
            }
        }
    }

    // MARK: - 纯度筛选
    private var purityFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(purityOptions, id: \.value) { option in
                    FilterChip(
                        title: option.label,
                        isSelected: viewModel.selectedPurity == option.value
                    ) {
                        withAnimation(.gallerySpring) {
                            viewModel.selectedPurity = option.value
                        }
                        Task { await viewModel.applyFilters() }
                    }
                }
            }
        }
    }

    // MARK: - 排序筛选
    private var sortingFilters: some View {
        simpleFilterGroup(
            title: "排序",
            options: viewModel.sortingOptionsForCurrentSource,
            selected: $viewModel.selectedSorting
        )
    }

    // MARK: - 分辨率筛选（简化版）
    private var resolutionFilters: some View {
        simpleFilterGroup(
            title: "分辨率",
            options: viewModel.resolutionFilterOptions,
            selected: $viewModel.selectedResolutionFilter
        )
    }

    // MARK: - 高级筛选按钮
    private var advancedFiltersButton: some View {
        Button {
            withAnimation(.gallerySpring) {
                showFilters.toggle()
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 12, weight: .bold))
                Text("高级筛选")
                    .font(.system(size: 13, weight: .bold))
                Image(systemName: showFilters ? "chevron.up" : "chevron.down")
                    .font(.system(size: 10, weight: .bold))
            }
            .foregroundStyle(LiquidGlassColors.textSecondary)
            .padding(.horizontal, 16)
            .frame(height: 32)
            .background {
                Capsule()
                    .fill(Color.white.opacity(0.03))
                    .overlay(Capsule().stroke(LiquidGlassColors.glassBorder, lineWidth: 0.5))
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - 高级筛选区域
    private var advancedFiltersSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 分辨率筛选
            filterSection(title: "分辨率", options: resolutionOptions) { resolution in
                if viewModel.selectedResolutions.contains(resolution.value) {
                    viewModel.selectedResolutions.removeAll { $0 == resolution.value }
                } else {
                    viewModel.selectedResolutions.append(resolution.value)
                }
                Task { await viewModel.applyFilters() }
            }

            // 比例筛选
            filterSection(title: "画面比例", options: ratioOptions) { ratio in
                if viewModel.selectedRatios.contains(ratio.value) {
                    viewModel.selectedRatios.removeAll { $0 == ratio.value }
                } else {
                    viewModel.selectedRatios.append(ratio.value)
                }
                Task { await viewModel.applyFilters() }
            }

            // 颜色筛选
            colorFilterSection
        }
        .padding(24)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(LiquidGlassColors.surfaceBackground.opacity(0.4))
                .background(.ultraThinMaterial)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(LiquidGlassColors.glassBorder, lineWidth: 0.5)
        }
    }

    // MARK: - 颜色筛选
    private var colorFilterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("主色调")
                .font(.system(size: 11, weight: .black))
                .kerning(1.5)
                .foregroundStyle(LiquidGlassColors.textQuaternary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 40), spacing: 12)], spacing: 12) {
                ForEach(colorOptions, id: \.value) { color in
                    colorChip(color: color)
                }
            }
        }
    }

    // MARK: - 瀑布流网格
    private var wallpaperGrid: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 220, maximum: 280), spacing: 32)],
            spacing: 32
        ) {
            ForEach(viewModel.wallpapers) { wallpaper in
                RemoteWallpaperCard(wallpaper: wallpaper) {
                    detailWallpaper = Wallpaper.from(remote: wallpaper)
                }
                .onAppear {
                    // 无限滚动：检测到最后几个元素时加载更多
                    if wallpaper.id == viewModel.wallpapers.last?.id {
                        Task { await viewModel.loadMore() }
                    }
                }
            }

            // 加载指示器
            if viewModel.isLoading {
                artisanLoadingIndicator
            }
        }
    }

    // MARK: - 空状态
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 64, weight: .thin))
                .foregroundStyle(LiquidGlassColors.textQuaternary)

            VStack(spacing: 8) {
                Text("未找到壁纸")
                    .font(.custom("Georgia", size: 20).bold())
                    .foregroundStyle(LiquidGlassColors.textPrimary)

                Text("尝试调整筛选条件或搜索关键词")
                    .font(.system(size: 13))
                    .foregroundStyle(LiquidGlassColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 100)
    }

    // MARK: - 错误横幅
    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14))
                .foregroundStyle(LiquidGlassColors.warningOrange)

            Text(message)
                .font(.system(size: 13))
                .foregroundStyle(LiquidGlassColors.textPrimary)

            Spacer()

            Button("重试") {
                Task { await viewModel.refresh() }
            }
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(LiquidGlassColors.primaryPink)
            .buttonStyle(.plain)
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(LiquidGlassColors.warningOrange.opacity(0.1))
                .background(.ultraThinMaterial)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(LiquidGlassColors.warningOrange.opacity(0.3), lineWidth: 0.5)
        }
    }

    // MARK: - 加载指示器
    private var artisanLoadingIndicator: some View {
        VStack(spacing: 16) {
            CustomProgressView(tint: LiquidGlassColors.primaryPink, scale: 1.2)
            Text("Fetching inspirations...")
                .font(.custom("Georgia", size: 12).italic())
                .foregroundStyle(LiquidGlassColors.textQuaternary)
        }
        .padding(.vertical, 60)
        .frame(maxWidth: .infinity)
    }

    // MARK: - 筛选组辅助函数
    private func artisanFilterGroup(
        title: String,
        options: [(label: String, value: String)],
        selected: Binding<String>
    ) -> some View {
        HStack(spacing: 14) {
            Text(title)
                .font(.system(size: 11, weight: .black))
                .kerning(1.5)
                .foregroundStyle(LiquidGlassColors.textQuaternary)

            HStack(spacing: 8) {
                ForEach(options, id: \.value) { option in
                    FilterChip(
                        title: option.label,
                        isSelected: selected.wrappedValue == option.value
                    ) {
                        withAnimation(.gallerySpring) {
                            selected.wrappedValue = option.value
                        }
                        Task { await viewModel.applyFilters() }
                    }
                }
            }
        }
    }

    private func simpleFilterGroup(
        title: String,
        options: [String],
        selected: Binding<String>
    ) -> some View {
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

    // MARK: - 通用筛选区域
    private func filterSection(
        title: String,
        options: [(label: String, value: String)],
        action: @escaping ((label: String, value: String)) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 11, weight: .black))
                .kerning(1.5)
                .foregroundStyle(LiquidGlassColors.textQuaternary)

            FlowLayout(spacing: 8) {
                ForEach(options, id: \.value) { option in
                    let isSelected = title == "分辨率"
                        ? viewModel.selectedResolutions.contains(option.value)
                        : viewModel.selectedRatios.contains(option.value)

                    FilterChip(title: option.label, isSelected: isSelected) {
                        action(option)
                    }
                }
            }
        }
    }

    // MARK: - 颜色芯片
    private func colorChip(color: (label: String, value: String, hex: String)) -> some View {
        let isSelected = viewModel.selectedColors.contains(color.value)

        return Button {
            if isSelected {
                viewModel.selectedColors.removeAll { $0 == color.value }
            } else {
                viewModel.selectedColors.append(color.value)
            }
            Task { await viewModel.applyFilters() }
        } label: {
            VStack(spacing: 6) {
                Circle()
                    .fill(Color(hex: color.hex))
                    .frame(width: 40, height: 40)
                    .overlay {
                        if isSelected {
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                            Circle()
                                .stroke(LiquidGlassColors.primaryPink, lineWidth: 3)
                                .padding(-2)
                        }
                    }

                Text(color.label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(
                        isSelected
                            ? LiquidGlassColors.primaryPink
                            : LiquidGlassColors.textSecondary
                    )
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - 数据定义
    private let purityOptions: [(label: String, value: String)] = [
        ("SFW", "100"),
        ("Sketchy", "010")
    ]

    private let sortingOptions: [(label: String, value: String)] = [
        ("最新", "date_added"),
        ("热门", "views"),
        ("收藏", "favorites"),
        ("随机", "random")
    ]

    private let resolutionOptions: [(label: String, value: String)] = [
        ("1920x1080", "1920x1080"),
        ("2560x1440", "2560x1440"),
        ("3840x2160", "3840x2160"),
        ("5120x2880", "5120x2880")
    ]

    private let ratioOptions: [(label: String, value: String)] = [
        ("16:9", "16x9"),
        ("16:10", "16x10"),
        ("21:9", "21x9"),
        ("32:9", "32x9"),
        ("9:16", "9x16")
    ]

    private let colorOptions: [(label: String, value: String, hex: String)] = [
        ("红", "660000", "CC0000"),
        ("橙", "cc6600", "FF8800"),
        ("黄", "ffcc00", "FFDD00"),
        ("绿", "009900", "00CC00"),
        ("青", "00cccc", "00DDDD"),
        ("蓝", "0066cc", "0088FF"),
        ("紫", "9900cc", "BB00FF"),
        ("粉", "ff66cc", "FF88DD"),
        ("黑", "000000", "222222"),
        ("白", "ffffff", "EEEEEE"),
        ("灰", "999999", "999999"),
        ("棕", "996633", "AA7744")
    ]
}
