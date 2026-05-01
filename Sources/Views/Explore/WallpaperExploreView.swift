import SwiftUI

// MARK: - WallpaperExploreView (Step 5: 壁纸探索页实现)
struct WallpaperExploreView: View {
    @State private var selectedCategory: String = "全部"
    @State private var selectedPurity: String = "SFW"
    @State private var selectedSort: String = "最新"
    
    // 分页状态
    @State var displayedWallpapers: [Wallpaper] = []
    @State var isLoadingMore = false
    @State var hasMoreData = true
    
    // Mock 数据
    let categories = [
        (title: "全部", icon: "sparkles", colors: [Color.orange, Color.red]),
        (title: "通用", icon: "photo.fill", colors: [Color.blue, Color.cyan]),
        (title: "风景", icon: "leaf.fill", colors: [Color.green, Color.mint]),
        (title: "建筑", icon: "building.2.fill", colors: [Color.purple, Color.indigo])
    ]
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 32) {
                // 1. 标题区
                VStack(alignment: .leading, spacing: 8) {
                    Text("壁纸库")
                        .font(.system(size: 32, weight: .bold, design: .serif))
                        .foregroundStyle(.white)
                    Text("探索数千张高画质 4K/8K 静态壁纸")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(.horizontal, 40)
                .padding(.top, 40)
                
                // 2. 筛选栏
                filterSection
                
                // 3. 壁纸网格
                LazyVGrid(
                    columns: [
                        GridItem(.adaptive(minimum: 200, maximum: 240), spacing: 20)
                    ],
                    spacing: 24
                ) {
                    ForEach(displayedWallpapers) { wallpaper in
                        WallpaperCard(wallpaper: wallpaper) {
                            // TODO: 打开详情弹窗
                        }
                    }
                    
                    // 任务 8: 加载更多触发器
                    if hasMoreData {
                        bottomLoadingIndicator
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            if displayedWallpapers.isEmpty {
                loadInitialData()
            }
        }
    }
    
    private var filterSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 分类芯片
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(categories, id: \.title) { cat in
                        CategoryChip(
                            title: cat.title,
                            icon: cat.icon,
                            colors: cat.colors,
                            isSelected: selectedCategory == cat.title
                        ) {
                            selectedCategory = cat.title
                            refreshData()
                        }
                    }
                }
                .padding(.horizontal, 40)
            }
            
            // 次级筛选
            HStack(spacing: 20) {
                filterGroup(title: "内容等级", options: ["SFW", "Sketchy"], selected: $selectedPurity)
                Divider().frame(height: 20).background(.white.opacity(0.1))
                filterGroup(title: "排序", options: ["最新", "热门", "收藏"], selected: $selectedSort)
                Spacer()
            }
            .padding(.horizontal, 40)
        }
    }
    
    private var bottomLoadingIndicator: some View {
        HStack {
            Spacer()
            VStack(spacing: 12) {
                CustomProgressView(tint: LiquidGlassColors.primaryPink, scale: 0.8)
                Text("正在载入更多...")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(LiquidGlassColors.textQuaternary)
            }
            .padding(.vertical, 40)
            .onAppear {
                loadMoreData()
            }
            Spacer()
        }
        // 这里的 frame 处理要符合规范
        .frame(maxWidth: .infinity)
        .gridCellColumns(1) // 如果是 LazyVGrid 且需要占满一行，通常用 gridCellColumns(2) 等
    }
    
    private func filterGroup(title: String, options: [String], selected: Binding<String>) -> some View {
        HStack(spacing: 12) {
            Text("\(title):")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.4))
            
            ForEach(options, id: \.self) { opt in
                FilterChip(title: opt, isSelected: selected.wrappedValue == opt) {
                    selected.wrappedValue = opt
                }
            }
        }
    }
}
