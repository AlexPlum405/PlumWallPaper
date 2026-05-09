import SwiftUI
import AppKit
import SwiftData

// MARK: - Artisan Studio View (Scheme C: Pure Edition with Two-Layer Filtering)
struct MyLibraryView: View {
    @State var viewModel = LibraryViewModel()
    @Environment(\.modelContext) private var modelContext
    @Query private var existingTags: [Tag]
    @Query private var allWallpapers: [Wallpaper]  // 直接监听 SwiftData 变化
    @State var isEditMode = false
    @State var selectedIDs = Set<UUID>()
    @State var toast: ToastConfig?
    @State var showDeleteConfirm = false
    @State var showImportSheet = false
    @State var showTagManager = false
    @State var detailWallpaper: Wallpaper?
    @State private var cardFrames: [UUID: CGRect] = [:]
    @State private var isDragSelecting = false
    @State private var dragSelectionAnchorID: UUID?
    @State private var dragSelectionBaseIDs = Set<UUID>()
    @State private var dragSelectionShouldSelect = true
    let mainPadding: CGFloat = 88

    var body: some View {
        ArtisanVerticalScrollView {
            VStack(alignment: .leading, spacing: 40) {
                // 1. 双层筛选工具栏
                artisanLibraryToolbar
                    .padding(.top, 100) // 避开 TabBar

                if filteredWallpapers.isEmpty {
                    artisanEmptyState
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 240, maximum: 300), spacing: 32)], spacing: 32) {
                        ForEach(filteredWallpapers) { wallpaper in
                            ZStack(alignment: .topTrailing) {
                                WallpaperCard(wallpaper: wallpaper) {
                                    if !isEditMode {
                                        // 点击时立即预加载
                                        if wallpaper.type == .video {
                                            let url = wallpaper.filePath.hasPrefix("http") ? URL(string: wallpaper.filePath) : URL(fileURLWithPath: wallpaper.filePath)
                                            if let url = url {
                                                PreviewResourcePipeline.shared.preloadVideo(url: url)
                                            }
                                        }
                                        detailWallpaper = wallpaper
                                    }
                                }
                                .scaleEffect(isEditMode ? 0.94 : 1.0)
                                .animation(.gallerySpring, value: isEditMode)
                                .background(cardFrameReader(for: wallpaper.id))
                                .onHover { isHovering in
                                    // hover 时预加载视频
                                    if isHovering && wallpaper.type == .video {
                                        let url = wallpaper.filePath.hasPrefix("http") ? URL(string: wallpaper.filePath) : URL(fileURLWithPath: wallpaper.filePath)
                                        if let url = url {
                                            PreviewResourcePipeline.shared.preloadVideo(url: url)
                                        }
                                    }
                                }

                                if isEditMode {
                                    cardSelectionOverlay(for: wallpaper.id)

                                    artisanSelectionIndicator(for: wallpaper.id)
                                        .padding(16)
                                        .allowsHitTesting(false)
                                        .transition(.scale.combined(with: .opacity))
                                }
                            }
                        }
                    }
                }
                Color.clear.frame(height: 120)
            }
            .padding(.horizontal, mainPadding).padding(.bottom, 100)
        }
        .coordinateSpace(name: "libraryGrid")
        .onPreferenceChange(LibraryCardFramePreferenceKey.self) { frames in
            cardFrames = frames
        }
        .background(LiquidGlassColors.deepBackground)
        .onAppear {
            viewModel.configure(modelContext: modelContext)
            preloadVisibleVideos()
            regenerateMissingThumbnailsIfNeeded()

            // 调试日志
            NSLog("[MyLibraryView] onAppear - 总壁纸数: \(allWallpapers.count)")
            let favoriteCount = allWallpapers.filter { $0.isFavorite }.count
            let onlineCount = allWallpapers.filter { $0.source == .online }.count
            let onlineFavoriteCount = allWallpapers.filter { $0.source == .online && $0.isFavorite }.count
            NSLog("[MyLibraryView] 收藏数: \(favoriteCount), 在线数: \(onlineCount), 在线收藏数: \(onlineFavoriteCount)")
            NSLog("[MyLibraryView] 当前筛选: typeFilter=\(viewModel.typeFilter.rawValue), sourceFilter=\(viewModel.sourceFilter.rawValue)")
            NSLog("[MyLibraryView] 筛选后壁纸数: \(filteredWallpapers.count)")
        }
        .onChange(of: allWallpapers) { oldValue, newValue in
            NSLog("[MyLibraryView] allWallpapers 变化: \(oldValue.count) -> \(newValue.count)")
        }
        .onChange(of: filteredWallpapers) { _, _ in
            preloadVisibleVideos()
            resetDragSelection()
        }
        .sheet(isPresented: $showImportSheet) { ImportWallpaperSheet(viewModel: viewModel, toast: $toast) }
        .sheet(isPresented: $showTagManager) { TagManagerSheet() }
        .sheet(item: $detailWallpaper) { wallpaper in
            WallpaperDetailView(
                wallpaper: wallpaper,
                onPrevious: { current, callback in
                    callback(getNavigateWallpaper(current: current, direction: -1))
                },
                onNext: { current, callback in
                    callback(getNavigateWallpaper(current: current, direction: 1))
                }
            )
        }
        .alert("确认删除", isPresented: $showDeleteConfirm) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) { batchDelete() }
        } message: {
            Text("确定要删除选中的 \(selectedIDs.count) 个壁纸吗？此操作不可撤销。")
        }
        .toast($toast)
    }

    // MARK: - Two-Layer Toolbar
    private var artisanLibraryToolbar: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Layer 1: Type Filter (Top Segment)
            HStack(spacing: 0) {
                ForEach(LibraryViewModel.WallpaperTypeFilter.allCases, id: \.self) { filter in
                    Button {
                        withAnimation(.gallerySpring) {
                            viewModel.typeFilter = filter
                            isEditMode = false
                            selectedIDs.removeAll()
                        }
                    } label: {
                        Text(filter.rawValue)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(viewModel.typeFilter == filter ? .white : LiquidGlassColors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(
                                viewModel.typeFilter == filter
                                    ? LiquidGlassColors.primaryPink
                                    : Color.white.opacity(0.05)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .frame(maxWidth: 400)

            // Layer 2: Source Filter + Actions
            HStack(alignment: .center) {
                // Source Filter Chips
                HStack(spacing: 12) {
                    ForEach(LibraryViewModel.WallpaperSourceFilter.allCases, id: \.self) { filter in
                        FilterChip(title: filter.rawValue, isSelected: viewModel.sourceFilter == filter) {
                            withAnimation(.gallerySpring) {
                                viewModel.sourceFilter = filter
                                isEditMode = false
                                selectedIDs.removeAll()
                            }
                        }
                    }
                }

                Spacer()

                // Action Buttons
                HStack(spacing: 16) {
                    // Edit Mode Toggle
                    Button {
                        withAnimation(.gallerySpring) {
                            if isEditMode {
                                isEditMode = false
                                selectedIDs.removeAll()
                            } else {
                                isEditMode = true
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: isEditMode ? "checkmark.circle.fill" : "square.dashed")
                            Text(isEditMode ? "完成" : "管理")
                        }
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(isEditMode ? LiquidGlassColors.primaryPink : LiquidGlassColors.textSecondary)
                        .padding(.horizontal, 16)
                        .frame(height: 34)
                        .galleryCardStyle(radius: 17, padding: 0)
                    }
                    .buttonStyle(.plain)

                    // Batch Actions (visible in edit mode)
                    if isEditMode {
                        Button {
                            toggleSelectAllVisible()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: areAllVisibleWallpapersSelected ? "checklist.unchecked" : "checklist.checked")
                                Text(areAllVisibleWallpapersSelected ? "清空" : "全选")
                            }
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(LiquidGlassColors.textSecondary)
                            .padding(.horizontal, 16)
                            .frame(height: 34)
                            .galleryCardStyle(radius: 17, padding: 0)
                        }
                        .buttonStyle(.plain)
                        .disabled(filteredWallpapers.isEmpty)
                    }

                    if isEditMode && !selectedIDs.isEmpty {
                        Button {
                            batchRemoveFavorites()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "heart.slash.fill")
                                Text("取消收藏")
                            }
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .frame(height: 34)
                            .background(Capsule().fill(Color.orange))
                        }
                        .buttonStyle(.plain)

                        Button {
                            showDeleteConfirm = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "trash.fill")
                                Text("删除")
                            }
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .frame(height: 34)
                            .background(Capsule().fill(Color.red))
                        }
                        .buttonStyle(.plain)
                    }

                    // Import Button (visible when not in edit mode)
                    if !isEditMode {
                        Button(action: { showTagManager = true }) {
                            HStack(spacing: 6) {
                                Image(systemName: "tag.fill")
                                Text("标签管理")
                            }
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(LiquidGlassColors.textSecondary)
                            .padding(.horizontal, 16)
                            .frame(height: 34)
                            .galleryCardStyle(radius: 17, padding: 0)
                        }
                        .buttonStyle(.plain)

                        Button(action: { showImportSheet = true }) {
                            Text("导入资源")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 16)
                                .frame(height: 34)
                                .background(Capsule().fill(LiquidGlassColors.primaryPink))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Layer 3: Tag Filter (Only show when there are tags and source is imported)
            if !existingTags.isEmpty && viewModel.sourceFilter == .imported {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        FilterChip(title: "全部", isSelected: viewModel.selectedTagFilter == nil) {
                            withAnimation(.gallerySpring) {
                                viewModel.selectedTagFilter = nil
                            }
                        }
                        ForEach(existingTags) { tag in
                            FilterChip(title: tag.name, isSelected: viewModel.selectedTagFilter == tag.name) {
                                withAnimation(.gallerySpring) {
                                    viewModel.selectedTagFilter = tag.name
                                }
                            }
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
    }
    
    // MARK: - Selection Indicator
    private func artisanSelectionIndicator(for id: UUID) -> some View {
        ZStack {
            Circle()
                .fill(selectedIDs.contains(id) ? LiquidGlassColors.primaryPink : Color.white.opacity(0.1))
                .frame(width: 30, height: 30)
                .background(.ultraThinMaterial, in: Circle())
            if selectedIDs.contains(id) {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(.white)
            }
        }
        .artisanShadow(color: selectedIDs.contains(id) ? LiquidGlassColors.primaryPink.opacity(0.4) : .clear, radius: 10)
    }
    
    // MARK: - Empty State
    private var artisanEmptyState: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 100)
            Image(systemName: "sparkle.magnifyingglass")
                .font(.system(size: 48, weight: .ultraLight))
                .foregroundStyle(LiquidGlassColors.textQuaternary)
            Text("暂无本地资源")
                .font(.custom("Georgia", size: 20).bold())
            Text("此处尚无艺术品陈列。")
                .font(.system(size: 13))
                .italic()
                .foregroundStyle(LiquidGlassColors.textQuaternary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Computed Properties
    private var filteredWallpapers: [Wallpaper] {
        var result = allWallpapers

        // 1. Apply type filter
        switch viewModel.typeFilter {
        case .all:
            break
        case .image:
            result = result.filter { $0.type == .image || $0.type == .heic }
        case .video:
            result = result.filter { $0.type == .video }
        }

        // 2. Apply source filter
        switch viewModel.sourceFilter {
        case .favorites:
            result = result.filter { $0.isFavorite }
        case .downloaded:
            result = result.filter { $0.source == .downloaded }
        case .imported:
            result = result.filter { $0.source == .imported }
        }

        // 3. Apply search filter
        if !viewModel.searchText.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(viewModel.searchText) }
        }

        // 4. Apply tag filter
        if let tagFilter = viewModel.selectedTagFilter {
            result = result.filter { wallpaper in
                wallpaper.tags.contains { $0.name == tagFilter }
            }
        }

        return result
    }

    private func getNavigateWallpaper(current: Wallpaper, direction: Int) -> Wallpaper {
        let wallpapers = filteredWallpapers
        guard !wallpapers.isEmpty else { return current }

        guard let currentIndex = wallpapers.firstIndex(where: { $0.id == current.id }) else {
            return wallpapers.first ?? current
        }

        let newIndex = (currentIndex + direction + wallpapers.count) % wallpapers.count
        return wallpapers[newIndex]
    }

    /// 预加载可见区域的视频
    private func preloadVisibleVideos() {
        let videoWallpapers = filteredWallpapers.filter { $0.type == .video }
        let urls = videoWallpapers.prefix(12).compactMap { wallpaper -> URL? in
            if wallpaper.filePath.hasPrefix("http") {
                return URL(string: wallpaper.filePath)
            } else {
                return URL(fileURLWithPath: wallpaper.filePath)
            }
        }

        if !urls.isEmpty {
            NSLog("[MyLibraryView] 预加载 \(urls.count) 个视频")
            PreviewResourcePipeline.shared.preloadVideos(urls: urls, limit: 12)
        }
    }

    /// 检测并修复因系统清理 Caches 而失效的本地缩略图
    private func regenerateMissingThumbnailsIfNeeded() {
        let fm = FileManager.default
        let stale = allWallpapers.filter { wallpaper in
            guard wallpaper.source != .online else { return false }
            guard let thumbPath = wallpaper.thumbnailPath, !thumbPath.isEmpty else { return false }
            // 跳过远程 URL 缩略图
            if thumbPath.hasPrefix("http") { return false }
            return !fm.fileExists(atPath: thumbPath)
        }
        guard !stale.isEmpty else { return }

        NSLog("[MyLibraryView] 发现 \(stale.count) 个失效缩略图，开始重建")

        Task.detached(priority: .utility) {
            for wallpaper in stale {
                let sourceURL = URL(fileURLWithPath: wallpaper.filePath)
                guard fm.fileExists(atPath: sourceURL.path) else { continue }
                let type = wallpaper.type
                if let newPath = try? await ThumbnailGenerator.shared.generateThumbnail(for: sourceURL, type: type) {
                    await MainActor.run {
                        wallpaper.thumbnailPath = newPath
                        try? modelContext.save()
                    }
                }
            }
        }
    }

    // MARK: - Actions
    private func toggleSelection(_ id: UUID) {
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
        } else {
            selectedIDs.insert(id)
        }
    }

    private var visibleWallpaperIDs: Set<UUID> {
        Set(filteredWallpapers.map(\.id))
    }

    private var areAllVisibleWallpapersSelected: Bool {
        let ids = visibleWallpaperIDs
        return !ids.isEmpty && ids.isSubset(of: selectedIDs)
    }

    private func toggleSelectAllVisible() {
        let ids = visibleWallpaperIDs
        guard !ids.isEmpty else { return }

        withAnimation(.gallerySpring) {
            if ids.isSubset(of: selectedIDs) {
                selectedIDs.subtract(ids)
            } else {
                selectedIDs.formUnion(ids)
            }
        }
    }

    private func cardFrameReader(for id: UUID) -> some View {
        GeometryReader { proxy in
            Color.clear.preference(
                key: LibraryCardFramePreferenceKey.self,
                value: [id: proxy.frame(in: .named("libraryGrid"))]
            )
        }
    }

    private func cardSelectionOverlay(for id: UUID) -> some View {
        Rectangle()
            .fill(Color.clear)
            .contentShape(Rectangle())
            .gesture(dragSelectionGesture(startingAt: id))
    }

    private func dragSelectionGesture(startingAt id: UUID) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named("libraryGrid"))
            .onChanged { value in
                beginDragSelection(from: id)
                updateDragSelection(at: value.location)
            }
            .onEnded { _ in
                resetDragSelection()
            }
    }

    private func beginDragSelection(from id: UUID) {
        guard isEditMode else { return }

        if !isDragSelecting {
            isDragSelecting = true
            dragSelectionAnchorID = id
            dragSelectionBaseIDs = selectedIDs
            dragSelectionShouldSelect = !selectedIDs.contains(id)
        }

        updateRangeSelection(to: id)
    }

    private func updateDragSelection(at location: CGPoint) {
        guard isEditMode, isDragSelecting else { return }
        guard let id = cardID(at: location) else { return }
        updateRangeSelection(to: id)
    }

    private func cardID(at location: CGPoint) -> UUID? {
        let visibleIDs = visibleWallpaperIDs
        if let directHit = cardFrames.first(where: { id, frame in
            visibleIDs.contains(id) && frame.insetBy(dx: -18, dy: -18).contains(location)
        })?.key {
            return directHit
        }

        return cardFrames
            .filter { visibleIDs.contains($0.key) }
            .min { lhs, rhs in
                lhs.value.distance(to: location) < rhs.value.distance(to: location)
            }
            .flatMap { entry in
                entry.value.distance(to: location) <= 96 ? entry.key : nil
            }
    }

    private func updateRangeSelection(to currentID: UUID) {
        guard let anchorID = dragSelectionAnchorID,
              let anchorIndex = filteredWallpapers.firstIndex(where: { $0.id == anchorID }),
              let currentIndex = filteredWallpapers.firstIndex(where: { $0.id == currentID })
        else { return }

        let range = min(anchorIndex, currentIndex)...max(anchorIndex, currentIndex)
        let rangeIDs = Set(filteredWallpapers[range].map(\.id))
        var nextSelection = dragSelectionBaseIDs

        if dragSelectionShouldSelect {
            nextSelection.formUnion(rangeIDs)
        } else {
            nextSelection.subtract(rangeIDs)
        }

        selectedIDs = nextSelection
    }

    private func resetDragSelection() {
        isDragSelecting = false
        dragSelectionAnchorID = nil
        dragSelectionBaseIDs.removeAll()
    }

    private func batchDelete() {
        let wallpapersToDelete = viewModel.wallpapers.filter { selectedIDs.contains($0.id) }
        for wallpaper in wallpapersToDelete {
            viewModel.deleteWallpaper(wallpaper)
        }
        selectedIDs.removeAll()
        isEditMode = false
        toast = ToastConfig(message: "已删除 \(wallpapersToDelete.count) 个壁纸", type: .success)
    }

    private func batchRemoveFavorites() {
        let wallpapersToUpdate = viewModel.wallpapers.filter { selectedIDs.contains($0.id) }
        for wallpaper in wallpapersToUpdate {
            if wallpaper.isFavorite {
                viewModel.toggleFavorite(wallpaper)
            }
        }
        selectedIDs.removeAll()
        isEditMode = false
        toast = ToastConfig(message: "已取消 \(wallpapersToUpdate.count) 个收藏", type: .info)
    }
}

private struct LibraryCardFramePreferenceKey: PreferenceKey {
    static var defaultValue: [UUID: CGRect] = [:]

    static func reduce(value: inout [UUID: CGRect], nextValue: () -> [UUID: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

private extension CGRect {
    func distance(to point: CGPoint) -> CGFloat {
        let dx = max(minX - point.x, 0, point.x - maxX)
        let dy = max(minY - point.y, 0, point.y - maxY)
        return hypot(dx, dy)
    }
}
