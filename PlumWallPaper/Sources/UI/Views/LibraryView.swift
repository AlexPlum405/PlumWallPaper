import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Wallpaper.importDate, order: .reverse) private var allWallpapers: [Wallpaper]
    @Query private var tags: [Tag]
    @Environment(AppViewModel.self) private var viewModel

    @State private var searchText = ""
    @State private var selectedTab: String = "DISCOVER"
    @State private var selectedTagName: String = "全部"
    @Namespace private var sidelineNamespace
    
    // 侧边栏选项
    let sidelineTabs = [
        (name: "DISCOVER", icon: "sparkles"),
        (name: "COLLECTIONS", icon: "folder.fill"),
        (name: "RECENT", icon: "clock.arrow.circlepath"),
        (name: "FAVORITES", icon: "heart.fill")
    ]
    
    var filteredWallpapers: [Wallpaper] {
        allWallpapers.filter { wallpaper in
            // 侧边栏基础过滤
            let matchesTab: Bool
            switch selectedTab {
            case "FAVORITES": matchesTab = wallpaper.isFavorite
            case "RECENT": matchesTab = true // 可以按时间排序，这里由 @Query 处理
            default: matchesTab = true
            }
            
            // 顶部搜索与标签过滤
            let matchesSearch = searchText.isEmpty || wallpaper.name.localizedCaseInsensitiveContains(searchText)
            let matchesTag = selectedTagName == "全部" || wallpaper.tags.contains(where: { $0.name == selectedTagName })
            
            return matchesTab && matchesSearch && matchesTag
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // --- 1. Sideline Tab (垂直分段导航) ---
            VStack(alignment: .leading, spacing: 40) {
                Spacer().frame(height: 120)
                
                ForEach(sidelineTabs, id: \.name) { tab in
                    Button(action: { withAnimation(.interactiveSpring(response: 0.4, dampingFraction: 0.7)) { selectedTab = tab.name } }) {
                        HStack(spacing: 16) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 18))
                            Text(tab.name)
                                .font(Theme.Fonts.ui(size: 13, weight: .bold))
                                .tracking(2)
                                .scaleEffect(selectedTab == tab.name ? 1.05 : 1.0)
                        }
                        .foregroundColor(selectedTab == tab.name ? .white : .white.opacity(0.25))
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .overlay(
                            ZStack {
                                if selectedTab == tab.name {
                                    Rectangle()
                                        .fill(Theme.accent)
                                        .frame(width: 3, height: 24)
                                        .cornerRadius(2)
                                        .matchedGeometryEffect(id: "sideline", in: sidelineNamespace)
                                        .padding(.leading, -24)
                                }
                            },
                            alignment: .leading
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Spacer()
            }
            .frame(width: 220)
            .padding(.leading, 60)
            
            // --- 2. 主内容区域 ---
            VStack(spacing: 0) {
                // 顶部工具栏
                VStack(spacing: 32) {
                    HStack(spacing: 32) {
                        // 搜索框 (原型样式)
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.white.opacity(0.3))
                            TextField("SEARCH WALLPAPERS...", text: $searchText)
                                .textFieldStyle(PlainTextFieldStyle())
                                .font(Theme.Fonts.ui(size: 13))
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(Theme.glass)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.glassBorder, lineWidth: 1))
                        .cornerRadius(14)
                        .frame(width: 400)
                        
                        Spacer()
                        
                        // 排序选项 (原型中的下拉感)
                        HStack(spacing: 8) {
                            Text("SORT BY: RECENT")
                                .font(Theme.Fonts.ui(size: 11, weight: .bold))
                                .opacity(0.4)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10))
                                .opacity(0.3)
                        }
                    }
                    
                    // 标签 Chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            LibraryTagBtn(name: "全部", isActive: selectedTagName == "全部") { selectedTagName = "全部" }
                            ForEach(tags) { tag in
                                LibraryTagBtn(name: tag.name, isActive: selectedTagName == tag.name) { selectedTagName = tag.name }
                            }
                            
                            // 模拟一些预置标签
                            LibraryTagBtn(name: "NATURAL", isActive: false) {}
                            LibraryTagBtn(name: "ABSTRACT", isActive: false) {}
                            LibraryTagBtn(name: "MINIMAL", isActive: false) {}
                        }
                    }
                }
                .padding(.horizontal, 60)
                .padding(.top, 120)
                .padding(.bottom, 60)
                
                // 壁纸网格
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 40),
                        GridItem(.flexible(), spacing: 40),
                        GridItem(.flexible(), spacing: 40)
                    ], spacing: 48) {
                        ForEach(filteredWallpapers) { wallpaper in
                            WallpaperGridCard(wallpaper: wallpaper, isNew: false)
                                .contextMenu {
                                    Button { viewModel.smartSetWallpaper(wallpaper) } label: {
                                        Label("设为壁纸", systemImage: "desktopcomputer")
                                    }
                                    Button { viewModel.showColorAdjust(wallpaper) } label: {
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
                    .padding(.horizontal, 60)
                    .padding(.bottom, 100)
                }
            }
        }
        .background(Theme.bg.edgesIgnoringSafeArea(.all))
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

// --- 专用子组件 ---

struct LibraryTagBtn: View {
    let name: String
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(name.uppercased())
                .font(Theme.Fonts.ui(size: 11, weight: .bold))
                .tracking(1)
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
                .background(isActive ? Theme.accent : Theme.glass)
                .foregroundColor(isActive ? .white : .white.opacity(0.4))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isActive ? Theme.accent : Theme.glassBorder, lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
