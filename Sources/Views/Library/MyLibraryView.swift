import SwiftUI
import AppKit

// MARK: - Artisan Studio View (Scheme C: Pure Edition with Two-Layer Filtering)
struct MyLibraryView: View {
    @State var viewModel = LibraryViewModel()
    @State var isEditMode = false
    @State var selectedIDs = Set<UUID>()
    @State var toast: ToastConfig?
    @State var showDeleteConfirm = false
    @State var showImportSheet = false
    @State var detailWallpaper: Wallpaper?
    let mainPadding: CGFloat = 88

    var body: some View {
        ScrollView(showsIndicators: false) {
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
                                    if isEditMode { toggleSelection(wallpaper.id) }
                                    else { detailWallpaper = wallpaper }
                                }
                                .scaleEffect(isEditMode ? 0.94 : 1.0)
                                .animation(.gallerySpring, value: isEditMode)

                                if isEditMode {
                                    artisanSelectionIndicator(for: wallpaper.id)
                                        .padding(16).transition(.scale.combined(with: .opacity))
                                }
                            }
                        }
                    }
                }
                Color.clear.frame(height: 120)
            }
            .padding(.horizontal, mainPadding).padding(.bottom, 100)
        }
        .background(LiquidGlassColors.deepBackground)
        .sheet(isPresented: $showImportSheet) { ImportWallpaperSheet(viewModel: viewModel, toast: $toast) }
        .sheet(item: $detailWallpaper) { wallpaper in
            WallpaperDetailView(wallpaper: wallpaper)
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
        viewModel.filteredWallpapers
    }

    // MARK: - Actions
    private func toggleSelection(_ id: UUID) {
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
        } else {
            selectedIDs.insert(id)
        }
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
