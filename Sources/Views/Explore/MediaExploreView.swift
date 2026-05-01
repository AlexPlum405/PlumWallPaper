import SwiftUI

// MARK: - MediaExploreView (Step 5: 媒体探索页实现)
struct MediaExploreView: View {
    @State private var selectedResolution: String = "全部"
    @State private var selectedSort: String = "最新"
    
    // 分页状态
    @State private var displayedMedia: [Wallpaper] = []
    @State private var isLoadingMore = false
    @State private var hasMoreData = true

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 32) {
                // 1. 标题区
                VStack(alignment: .leading, spacing: 8) {
                    Text("动态媒体")
                        .font(.system(size: 32, weight: .bold, design: .serif))
                        .foregroundStyle(.white)
                    Text("沉浸式动态壁纸与视觉特效")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(.horizontal, 40)
                .padding(.top, 40)
                
                // 2. 筛选栏
                HStack(spacing: 24) {
                    filterGroup(title: "分辨率", options: ["全部", "4K", "2K", "1080P"], selected: $selectedResolution)
                    Divider().frame(height: 20).background(.white.opacity(0.1))
                    filterGroup(title: "排序", options: ["最新", "热门", "评价"], selected: $selectedSort)
                    Spacer()
                }
                .padding(.horizontal, 40)
                
                // 3. 媒体网格
                LazyVGrid(
                    columns: [
                        GridItem(.adaptive(minimum: 200, maximum: 240), spacing: 20)
                    ],
                    spacing: 24
                ) {
                    ForEach(displayedMedia) { item in
                        WallpaperCard(wallpaper: item) {
                            // TODO: 打开详情弹窗
                        }
                    }
                    
                    if hasMoreData {
                        bottomLoadingIndicator
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            if displayedMedia.isEmpty {
                loadInitialData()
            }
        }
    }
    
    private var bottomLoadingIndicator: some View {
        HStack {
            Spacer()
            VStack(spacing: 12) {
                CustomProgressView(tint: LiquidGlassColors.primaryPink, scale: 0.8)
                Text("正在扫描渲染管线...")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(LiquidGlassColors.textQuaternary)
            }
            .padding(.vertical, 40)
            .onAppear {
                loadMoreData()
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - 逻辑
    
    private func loadInitialData() {
        displayedMedia = createMockBatch(count: 10)
    }
    
    private func loadMoreData() {
        guard !isLoadingMore && hasMoreData else { return }
        isLoadingMore = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            let newBatch = createMockBatch(count: 6)
            displayedMedia.append(contentsOf: newBatch)
            isLoadingMore = false
            
            if displayedMedia.count > 30 {
                hasMoreData = false
            }
        }
    }
    
    private func createMockBatch(count: Int) -> [Wallpaper] {
        let baseCount = displayedMedia.count
        return (0..<count).map { i in
            Wallpaper(
                id: UUID(),
                name: "引擎资源 #\(baseCount + i + 1)",
                filePath: "https://mock.placeholder/media\(baseCount + i).jpg",
                type: .video,
                resolution: "4K · 60FPS",
                duration: Double.random(in: 15...120), // 随机时长
                thumbnailPath: ""
            )
        }
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
