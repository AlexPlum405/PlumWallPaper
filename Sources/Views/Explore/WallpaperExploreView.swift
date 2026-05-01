import SwiftUI

// MARK: - Artisan Wallpaper Explore (Scheme C: Pure Edition)
struct WallpaperExploreView: View {
    @State private var selectedCategory: String = "全部"
    @State private var selectedPurity: String = "SFW"
    @State private var selectedSort: String = "最新"
    
    @State var displayedWallpapers: [Wallpaper] = []
    @State var isLoadingMore = false
    @State var hasMoreData = true
    @State var detailWallpaper: Wallpaper?
    
    let mainPadding: CGFloat = 88
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 48) {
                // 1. 顶部筛选 (修复：移除 Hero，增加顶部避让)
                artisanFilterSection
                    .padding(.top, 100) // 避开 TabBar
                
                // 2. 瀑布流画卷
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 220, maximum: 280), spacing: 32)], spacing: 32) {
                    ForEach(displayedWallpapers) { wallpaper in
                        WallpaperCard(wallpaper: wallpaper) { 
                            detailWallpaper = wallpaper
                        }
                    }
                    if hasMoreData { artisanLoadingIndicator }
                }
            }
            .padding(.horizontal, mainPadding).padding(.bottom, 100)
        }
        .background(LiquidGlassColors.deepBackground)
        .sheet(item: $detailWallpaper) { wallpaper in
            WallpaperDetailView(wallpaper: wallpaper)
        }
        .onAppear { if displayedWallpapers.isEmpty { loadInitialData() } }
    }
    
    private var artisanFilterSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(["全部", "风景", "建筑", "极简", "抽象"], id: \.self) { cat in
                        FilterChip(title: cat, isSelected: selectedCategory == cat) {
                            withAnimation(.gallerySpring) { selectedCategory = cat; refreshData() }
                        }
                    }
                }
            }
            HStack(spacing: 32) {
                artisanFilterGroup(title: "内容分级", options: ["SFW", "Sketchy"], selected: $selectedPurity)
                Rectangle().fill(LiquidGlassColors.glassBorder).frame(width: 1, height: 20)
                artisanFilterGroup(title: "排序权重", options: ["最新", "热门", "收藏"], selected: $selectedSort)
            }
        }
    }
    
    private func artisanFilterGroup(title: String, options: [String], selected: Binding<String>) -> some View {
        HStack(spacing: 14) {
            Text(title).font(.system(size: 11, weight: .black)).kerning(1.5).foregroundStyle(LiquidGlassColors.textQuaternary)
            HStack(spacing: 8) {
                ForEach(options, id: \.self) { opt in
                    FilterChip(title: opt, isSelected: selected.wrappedValue == opt) {
                        withAnimation(.gallerySpring) { selected.wrappedValue = opt; refreshData() }
                    }
                }
            }
        }
    }
    
    private var artisanLoadingIndicator: some View {
        VStack(spacing: 16) { CustomProgressView(tint: LiquidGlassColors.primaryPink, scale: 1.2); Text("Fetching inspirations...").font(.custom("Georgia", size: 12).italic()).foregroundStyle(LiquidGlassColors.textQuaternary) }
            .padding(.vertical, 60).onAppear { loadMoreData() }.frame(maxWidth: .infinity)
    }
}
