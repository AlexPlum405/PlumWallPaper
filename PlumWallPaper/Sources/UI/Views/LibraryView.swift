import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Wallpaper.importDate, order: .reverse) private var allWallpapers: [Wallpaper]
    @Query private var tags: [Tag]
    
    @State private var searchText = ""
    @State private var selectedTagName: String? = "全部"
    @State private var showingColorAdjust: Wallpaper? = nil
    @State private var showingMonitorSelector: Wallpaper? = nil
    
    var filteredWallpapers: [Wallpaper] {
        allWallpapers.filter { wallpaper in
            let matchesSearch = searchText.isEmpty || wallpaper.name.localizedCaseInsensitiveContains(searchText)
            let matchesTag = selectedTagName == "全部" || wallpaper.tags.contains(where: { $0.name == selectedTagName })
            return matchesSearch && matchesTag
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // --- 顶部筛选栏 ---
            HStack(spacing: 24) {
                // 搜索框
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white.opacity(0.3))
                    TextField("搜索壁纸名称...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Theme.glass)
                .cornerRadius(12)
                .frame(width: 300)
                
                // 标签过滤器
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        TagFilterBtn(name: "全部", isActive: selectedTagName == "全部") { selectedTagName = "全部" }
                        TagFilterBtn(name: "收藏", isActive: selectedTagName == "收藏") { selectedTagName = "收藏" }
                        
                        ForEach(tags) { tag in
                            TagFilterBtn(name: tag.name, isActive: selectedTagName == tag.name) { selectedTagName = tag.name }
                        }
                    }
                }
            }
            .padding(.horizontal, 80)
            .padding(.top, 120) // 对齐基准
            .padding(.bottom, 40)
            
            // --- 壁纸网格 ---
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 320), spacing: 32)], spacing: 40) {
                    ForEach(filteredWallpapers) { wallpaper in
                        LibraryCard(wallpaper: wallpaper)
                            .contextMenu {
                                Button { showingMonitorSelector = wallpaper } label: {
                                    Label("设为壁纸", systemImage: "desktopcomputer")
                                }
                                Button { showingColorAdjust = wallpaper } label: {
                                    Label("色彩调节", systemImage: "slider.horizontal.3")
                                }
                                Divider()
                                Button { toggleFavorite(wallpaper) } label: {
                                    Label(wallpaper.isFavorite ? "取消收藏" : "加入收藏", systemImage: wallpaper.isFavorite ? "heart.slash" : "heart")
                                }
                                Button(role: .destructive) { deleteWallpaper(wallpaper) } label: {
                                    Label("从库中移除", systemImage: "trash")
                                }
                            }
                    }
                }
                .padding(.horizontal, 80)
                .padding(.bottom, 80)
            }
        }
        .background(Theme.bg.edgesIgnoringSafeArea(.all))
        .fullScreenCover(item: $showingColorAdjust) { wallpaper in
            ColorAdjustView(wallpaper: wallpaper)
        }
        .sheet(item: $showingMonitorSelector) { wallpaper in
            MonitorSelectorView(wallpaper: wallpaper)
        }
    }
    
    // --- 逻辑 ---
    
    func toggleFavorite(_ wallpaper: Wallpaper) {
        wallpaper.isFavorite.toggle()
        try? modelContext.save()
    }
    
    func deleteWallpaper(_ wallpaper: Wallpaper) {
        modelContext.delete(wallpaper)
        try? modelContext.save()
    }
}

struct TagFilterBtn: View {
    let name: String
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(name)
                .font(.system(size: 13, weight: .bold))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isActive ? Theme.accent : Theme.glass)
                .foregroundColor(isActive ? .white : .white.opacity(0.5))
                .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct LibraryCard: View {
    let wallpaper: Wallpaper
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ZStack {
                // 缩略图
                if let thumbData = try? Data(contentsOf: URL(fileURLWithPath: wallpaper.thumbnailPath)),
                   let nsImage = NSImage(data: thumbData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity)
                        .aspectRatio(16/9, contentMode: .fill)
                        .cornerRadius(16)
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.05))
                        .aspectRatio(16/9, contentMode: .fit)
                }
                
                // 悬停 Aura
                if isHovered {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                }
                
                // 类型标识
                VStack {
                    HStack {
                        Spacer()
                        Text(wallpaper.type == .video ? "VIDEO" : "HEIC")
                            .font(.system(size: 9, weight: .black))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(4)
                    }
                    Spacer()
                }
                .padding(12)
            }
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
            .onHover { isHovered = $0 }
            
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(wallpaper.name)
                        .font(.system(size: 15, weight: .bold))
                    Text("\(wallpaper.resolution) · \(ByteCountFormatter.string(fromByteCount: wallpaper.fileSize, countStyle: .file))")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.3))
                }
                Spacer()
                if wallpaper.isFavorite {
                    Image(systemName: "heart.fill")
                        .foregroundColor(Theme.accent)
                        .font(.system(size: 12))
                }
            }
        }
    }
}

extension Wallpaper: Identifiable {}
