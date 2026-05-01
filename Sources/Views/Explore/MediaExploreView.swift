import SwiftUI

// MARK: - Artisan Media Explore (Scheme C: Pure Edition)
struct MediaExploreView: View {
    @State var selectedResolution: String = "全部"
    @State var selectedSort: String = "最新"
    @State var displayedMedia: [Wallpaper] = []
    @State var isLoadingMore = false
    @State var hasMoreData = true
    @State var detailWallpaper: Wallpaper?
    let mainPadding: CGFloat = 88

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 48) {
                // 1. 筛选组 (修复：移除 Hero，增加顶部避让)
                HStack(spacing: 32) {
                    artisanFilterGroup(title: "物理分辨率", options: ["全部", "4K", "2K", "1080P"], selected: $selectedResolution)
                    Rectangle().fill(LiquidGlassColors.glassBorder).frame(width: 1, height: 20)
                    artisanFilterGroup(title: "热度排序", options: ["最新", "热门", "评价"], selected: $selectedSort)
                }
                .padding(.top, 100) // 避开悬浮 TabBar
                
                // 2. 网格流
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 220, maximum: 280), spacing: 32)], spacing: 32) {
                    ForEach(displayedMedia) { item in
                        WallpaperCard(wallpaper: item) { 
                            detailWallpaper = item
                        }
                    }
                    if hasMoreData { artisanCinematicLoading }
                }
            }
            .padding(.horizontal, mainPadding).padding(.bottom, 100)
        }
        .background(LiquidGlassColors.deepBackground)
        .sheet(item: $detailWallpaper) { wallpaper in
            WallpaperDetailView(wallpaper: wallpaper)
        }
        .onAppear { if displayedMedia.isEmpty { loadInitialData() } }
    }

    private func artisanFilterGroup(title: String, options: [String], selected: Binding<String>) -> some View {
        HStack(spacing: 14) {
            Text(title).font(.system(size: 11, weight: .black)).kerning(1.5).foregroundStyle(LiquidGlassColors.textQuaternary)
            HStack(spacing: 8) {
                ForEach(options, id: \.self) { opt in
                    FilterChip(title: opt, isSelected: selected.wrappedValue == opt) {
                        withAnimation(.gallerySpring) { selected.wrappedValue = opt }
                    }
                }
            }
        }
    }
    
    private var artisanCinematicLoading: some View {
        VStack(spacing: 16) { CustomProgressView(tint: LiquidGlassColors.primaryPink, scale: 1.2); Text("Synchronizing cinematic flow...").font(.custom("Georgia", size: 12).italic()).foregroundStyle(LiquidGlassColors.textQuaternary) }
            .padding(.vertical, 60).onAppear { loadMoreData() }.frame(maxWidth: .infinity)
    }
}
