import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppViewModel.self) private var viewModel
    @Query(sort: \Wallpaper.importDate, order: .reverse) private var wallpapers: [Wallpaper]
    
    @State private var activeId: UUID? = nil
    @Namespace private var animation
    
    var activeWallpaper: Wallpaper? {
        if let id = activeId {
            return wallpapers.first(where: { $0.id == id })
        }
        return wallpapers.first
    }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                // --- Hero Section (100% 原型还原) ---
                ZStack(alignment: .bottomLeading) {
                    // 1. 背景层 (带 1.2s 缓动切换感，通过视图状态控制)
                    ZStack {
                        if let wallpaper = activeWallpaper,
                           let thumbData = try? Data(contentsOf: URL(fileURLWithPath: wallpaper.thumbnailPath)),
                           let nsImage = NSImage(data: thumbData) {
                            Image(nsImage: nsImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .transition(.opacity.animation(.easeInOut(duration: 1.2)))
                                .id(wallpaper.id)
                        } else {
                            Color.black
                        }
                    }
                    .frame(height: 850)
                    .clipped()
                    // 2. 渐变叠加 (原型中的双层渐变)
                    .overlay(
                        ZStack {
                            LinearGradient(
                                stops: [
                                    .init(color: .clear, location: 0.5),
                                    .init(color: Theme.bg, location: 1.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        }
                    )
                    
                    // 3. 内容层
                    if let wallpaper = activeWallpaper {
                        VStack(alignment: .leading, spacing: 0) {
                            HStack(spacing: 8) {
                                Text("Jewel Curated ·")
                                    .font(Theme.Fonts.ui(size: 12, weight: .semibold))
                                Text(wallpaper.tags.first?.name.uppercased() ?? "NATURAL")
                                    .font(Theme.Fonts.ui(size: 12, weight: .semibold))
                            }
                            .foregroundColor(Theme.accent)
                            .tracking(3)
                            .padding(.bottom, 16)
                            
                            Text(wallpaper.name)
                                .font(Theme.Fonts.display(size: 84))
                                .fontWeight(.medium)
                                .italic()
                                .foregroundColor(.white)
                                .padding(.bottom, 24)
                                .shadow(color: .black.opacity(0.3), radius: 30, x: 0, y: 10)
                            
                            HStack(spacing: 40) {
                                Text("TYPE: \(wallpaper.type == .video ? "VIDEO" : "HEIC")")
                                Text("RES: \(wallpaper.resolution)")
                                Text("SIZE: \(ByteCountFormatter.string(fromByteCount: wallpaper.fileSize, countStyle: .file))")
                                if let duration = wallpaper.duration {
                                    Text("TIME: \(formatDuration(duration))")
                                }
                            }
                            .font(Theme.Fonts.ui(size: 13))
                            .foregroundColor(.white.opacity(0.4))
                            .tracking(1)
                            .padding(.bottom, 40)
                            
                            HStack(spacing: 16) {
                                Button(action: { setWallpaper(wallpaper) }) {
                                    Text("设为壁纸")
                                        .font(Theme.Fonts.ui(size: 14, weight: .bold))
                                        .padding(.horizontal, 36)
                                        .padding(.vertical, 14)
                                        .background(Color.white)
                                        .foregroundColor(.black)
                                        .cornerRadius(12)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Button(action: { toggleFavorite(wallpaper) }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "heart.fill")
                                        Text("收藏")
                                    }
                                    .font(Theme.Fonts.ui(size: 14, weight: .bold))
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 14)
                                    .background(Theme.glassHeavy)
                                    .plumGlass(cornerRadius: 12)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.leading, 80)
                        .padding(.bottom, 260) // 为缩略图条腾出空间
                    }
                    
                    // 4. 浮动缩略图条 (横向滚动 + 激活高亮)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(wallpapers.prefix(10)) { w in
                                ThumbCard(
                                    thumbnailPath: w.thumbnailPath,
                                    isActive: (activeId ?? wallpapers.first?.id) == w.id,
                                    onSelect: { 
                                        withAnimation(.easeInOut(duration: 0.6)) { activeId = w.id }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 80)
                    }
                    .padding(.bottom, 40)
                }
                .frame(height: 850)
                
                // --- Grid Sections (最近添加, 收藏等) ---
                VStack(spacing: 100) {
                    renderSection(title: "最近添加", items: wallpapers.prefix(4))
                    if let favs = try? wallpapers.filter({ $0.isFavorite }).prefix(4), !favs.isEmpty {
                        renderSection(title: "收藏的作品", items: Array(favs))
                    }
                }
                .padding(.top, 80)
                .padding(.horizontal, 80)
                .padding(.bottom, 140)
                .background(Theme.bg)
            }
        }
        .background(Theme.bg)
        .edgesIgnoringSafeArea(.all)
    }
    
    @ViewBuilder
    func renderSection(title: String, items: some Collection<Wallpaper>) -> some View {
        VStack(alignment: .leading, spacing: 32) {
            HStack(alignment: .center) {
                Text(title)
                    .font(Theme.Fonts.display(size: 38))
                    .italic()
                    .fontWeight(.medium)
                Spacer()
                HStack(spacing: 8) {
                    Text("查看全部")
                    Image(systemName: "play.fill").font(.system(size: 10))
                }
                .font(Theme.Fonts.ui(size: 13))
                .foregroundColor(.white.opacity(0.25))
            }
            
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 32), GridItem(.flexible(), spacing: 32), GridItem(.flexible(), spacing: 32), GridItem(.flexible(), spacing: 32)], spacing: 32) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, wallpaper in
                    WallpaperGridCard(wallpaper: wallpaper, isNew: title == "最近添加")
                }
            }
        }
    }
    
    // --- 逻辑 ---
    func setWallpaper(_ wallpaper: Wallpaper) {
        viewModel.smartSetWallpaper(wallpaper)
    }
    
    func toggleFavorite(_ wallpaper: Wallpaper) {
        wallpaper.isFavorite.toggle()
        try? modelContext.save()
    }
    
    func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: duration) ?? "00:00"
    }
}

// --- 组件还原 ---

struct ThumbCard: View {
    let thumbnailPath: String
    let isActive: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            Group {
                if let thumbData = try? Data(contentsOf: URL(fileURLWithPath: thumbnailPath)),
                   let nsImage = NSImage(data: thumbData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Color.white.opacity(0.05)
                }
            }
            .frame(width: 160, height: 90)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isActive ? Color.white : Color.white.opacity(0.1), lineWidth: isActive ? 2 : 1)
            )
            .opacity(isActive ? 1.0 : 0.4)
            .scaleEffect(isActive ? 1.0 : 0.98)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct WallpaperGridCard: View {
    let wallpaper: Wallpaper
    let isNew: Bool
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            ZStack {
                // Aura Glow 背景
                RadialGradient(colors: [Theme.accent.opacity(0.3), .clear], center: .center, startRadius: 0, endRadius: 180)
                    .blur(radius: 40)
                    .scaleEffect(isHovered ? 1.2 : 0.8)
                    .opacity(isHovered ? 1 : 0)
                    .frame(width: 300, height: 200)
                
                // 封面容器
                ZStack(alignment: .topLeading) {
                    if let thumbData = try? Data(contentsOf: URL(fileURLWithPath: wallpaper.thumbnailPath)),
                       let nsImage = NSImage(data: thumbData) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity)
                            .aspectRatio(16/9, contentMode: .fit)
                            .cornerRadius(24)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(isHovered ? Color.white.opacity(0.25) : Color.white.opacity(0.08), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(isHovered ? 0.6 : 0.2), radius: isHovered ? 40 : 20, x: 0, y: 10)
                    }
                    
                    if isNew {
                        Text("NEW")
                            .font(Theme.Fonts.ui(size: 9, weight: .black))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Theme.accent)
                            .cornerRadius(6)
                            .padding(16)
                            .shadow(color: Theme.accent.opacity(0.4), radius: 10)
                    }
                    
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            HStack(spacing: 6) {
                                Text(ByteCountFormatter.string(fromByteCount: wallpaper.fileSize, countStyle: .file))
                                if let duration = wallpaper.duration {
                                    Text(formatDuration(duration))
                                }
                            }
                            .font(Theme.Fonts.ui(size: 10, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.black.opacity(0.4))
                            .blur(radius: 0.1) // 模拟毛玻璃感
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.1), lineWidth: 1))
                            .padding(16)
                        }
                    }
                }
                .scaleEffect(isHovered ? 1.03 : 1.0)
            }
            .animation(.interactiveSpring(response: 0.5, dampingFraction: 0.8), value: isHovered)
            .onHover { isHovered = $0 }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(wallpaper.name)
                    .font(Theme.Fonts.ui(size: 17, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
                
                HStack(spacing: 8) {
                    Text(wallpaper.resolution)
                    Circle().frame(width: 3, height: 3).opacity(0.2)
                    Text(wallpaper.type == .video ? "VIDEO" : "HEIC")
                }
                .font(Theme.Fonts.ui(size: 13))
                .foregroundColor(.white.opacity(0.3))
            }
            .padding(.horizontal, 4)
        }
    }
    
    func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: duration) ?? "00:00"
    }
}
