import SwiftUI
import AppKit

// MARK: - Artisan Studio View (Scheme C: Pure Edition)
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
                // 1. 工具栏 (修复：移除 Hero，增加顶部避让)
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
        .toast($toast)
    }

    private var artisanLibraryToolbar: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    ForEach(LibraryViewModel.LibraryTab.allCases, id: \.self) { tab in
                        FilterChip(title: tab.rawValue, isSelected: viewModel.selectedTab == tab) {
                            withAnimation(.gallerySpring) { viewModel.selectedTab = tab; isEditMode = false; selectedIDs.removeAll() }
                        }
                    }
                }
            }
            Spacer()
            HStack(spacing: 16) {
                Button { withAnimation(.gallerySpring) { isEditMode.toggle() } } label: {
                    HStack(spacing: 8) {
                        Image(systemName: isEditMode ? "checkmark.circle.fill" : "square.dashed")
                        Text(isEditMode ? "完成" : "管理")
                    }.font(.system(size: 12, weight: .bold)).foregroundStyle(isEditMode ? LiquidGlassColors.primaryPink : LiquidGlassColors.textSecondary)
                    .padding(.horizontal, 16).frame(height: 34).galleryCardStyle(radius: 17, padding: 0)
                }.buttonStyle(.plain)

                if !isEditMode {
                    Button(action: { showImportSheet = true }) {
                        Text("导入资源").font(.system(size: 12, weight: .bold)).foregroundStyle(.white).padding(.horizontal, 16).frame(height: 34)
                            .background(Capsule().fill(LiquidGlassColors.primaryPink))
                    }.buttonStyle(.plain)
                }
            }
        }
    }
    
    private func artisanSelectionIndicator(for id: UUID) -> some View {
        ZStack {
            Circle().fill(selectedIDs.contains(id) ? LiquidGlassColors.primaryPink : Color.white.opacity(0.1)).frame(width: 30, height: 30).background(.ultraThinMaterial, in: Circle())
            if selectedIDs.contains(id) { Image(systemName: "checkmark").font(.system(size: 11, weight: .black)).foregroundStyle(.white) }
        }.artisanShadow(color: selectedIDs.contains(id) ? LiquidGlassColors.primaryPink.opacity(0.4) : .clear, radius: 10)
    }
    
    private var artisanEmptyState: some View {
        VStack(spacing: 24) { Spacer().frame(height: 100); Image(systemName: "sparkle.magnifyingglass").font(.system(size: 48, weight: .ultraLight)).foregroundStyle(LiquidGlassColors.textQuaternary); Text("暂无本地资源").font(.custom("Georgia", size: 20).bold()); Text("此处尚无艺术品陈列。").font(.system(size: 13)).italic().foregroundStyle(LiquidGlassColors.textQuaternary) }.frame(maxWidth: .infinity)
    }
}
