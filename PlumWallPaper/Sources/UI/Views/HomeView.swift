import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppViewModel.self) private var viewModel
    @Query(sort: \Wallpaper.importDate, order: .reverse) private var wallpapers: [Wallpaper]
    
    @State private var activeId: UUID? = nil
    @State private var hueRotation = 0.0
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
                // --- Hero Section (1:1 原型对齐) ---
                ZStack(alignment: .bottomLeading) {
                    // 1. 背景层
                    ZStack {
                        if let wallpaper = activeWallpaper,
                           let nsImage = (wallpaper.type == .video ? 
                                          NSImage(data: (try? Data(contentsOf: URL(fileURLWithPath: wallpaper.thumbnailPath))) ?? Data()) : 
                                          NSImage(contentsOfFile: wallpaper.filePath)) {
                            Image(nsImage: nsImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .transition(.opacity.animation(.easeInOut(duration: 1.2)))
                                .id(wallpaper.id)
                        } else {
                            Color.black
                        }
                        
                        // Noise Overlay
                        Color.black.opacity(0.03)
                    }
                    .frame(height: 1000)
                    .clipped()
                    
                    // 2. 渐变蒙版 (严格比例)
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .clear, location: 0.4),
                            .init(color: Theme.bg.opacity(0.6), location: 0.7),
                            .init(color: Theme.bg, location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    
                    // 3. 内容层
                    if let wallpaper = activeWallpaper {
                        VStack(alignment: .leading, spacing: 0) {
                            HStack(spacing: 12) {
                                Text("JEWEL CURATED")
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundColor(Theme.accent)
                                    .tracking(4)
                                
                                Text("·")
                                    .foregroundColor(.white.opacity(0.2))
                                
                                Text(wallpaper.tags.first?.name.uppercased() ?? "NATURAL")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(Theme.accent)
                                    .tracking(3)
                            }
                            .padding(.bottom, 28)
                            
                            Text(wallpaper.name)
                                .font(Theme.Fonts.display(size: 92, weight: .medium))
                                .italic()
                                .foregroundColor(.white)
                                .padding(.bottom, 32)
                                .shadow(color: .black.opacity(0.5), radius: 30, x: 0, y: 15)
                            
                            HStack(spacing: 40) {
                                Text("TYPE: \(wallpaper.type == .video ? "VIDEO" : "IMAGE")")
                                Text("RES: \(wallpaper.resolution)")
                                Text("SIZE: \(ByteCountFormatter.string(fromByteCount: wallpaper.fileSize, countStyle: .file))")
                                if let duration = wallpaper.duration {
                                    Text("TIME: \(formatDuration(duration))")
                                }
                            }
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                            .tracking(1)
                            .padding(.bottom, 48)
                            
                            HStack(spacing: 20) {
                                Button(action: { setWallpaper(wallpaper) }) {
                                    Text("设为壁纸")
                                        .font(.system(size: 15, weight: .bold))
                                        .padding(.horizontal, 44)
                                        .padding(.vertical, 16)
                                        .background(Color.white)
                                        .foregroundColor(.black)
                                        .cornerRadius(100)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Button(action: { toggleFavorite(wallpaper) }) {
                                    HStack(spacing: 10) {
                                        Image(systemName: wallpaper.isFavorite ? "heart.fill" : "heart")
                                        Text("收藏")
                                    }
                                    .font(.system(size: 15, weight: .bold))
                                    .padding(.horizontal, 32)
                                    .padding(.vertical, 16)
                                    .background(Theme.glassHeavy)
                                    .foregroundColor(.white)
                                    .cornerRadius(100)
                                    .overlay(RoundedRectangle(cornerRadius: 100).stroke(Color.white.opacity(0.1), lineWidth: 1))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.leading, 80)
                        .padding(.bottom, 320)
                    }
                    
                    // 4. 浮动缩略图条 (对齐截图中 16:9 圆角卡片样式)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
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
                    .padding(.bottom, 60)
                }
                .frame(height: 1000)
                
                // --- Grid Sections ---
                VStack(spacing: 100) {
                    renderSection(title: "最近添加", items: wallpapers.prefix(4))
                    if let favs = try? wallpapers.filter({ $0.isFavorite }).prefix(4), !favs.isEmpty {
                        renderSection(title: "收藏的作品", items: Array(favs))
                    }
                }
                .padding(.top, 100)
                .padding(.horizontal, 80)
                .padding(.bottom, 140)
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
                    .font(Theme.Fonts.display(size: 38, weight: .medium))
                    .italic()
                Spacer()
                HStack(spacing: 8) {
                    Text("查看全部")
                    Image(systemName: "play.fill").font(.system(size: 10))
                }
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white.opacity(0.25))
            }
            
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 40), GridItem(.flexible(), spacing: 40), GridItem(.flexible(), spacing: 40), GridItem(.flexible(), spacing: 40)], spacing: 40) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, wallpaper in
                    WallpaperGridCard(wallpaper: wallpaper, isNew: title == "最近添加")
                        .onTapGesture {
                            withAnimation(.spring(response: 0.6)) {
                                activeId = wallpaper.id
                            }
                        }
                        .contextMenu {
                            Button { setWallpaper(wallpaper) } label: {
                                Label("设为壁纸", systemImage: "desktopcomputer")
                            }
                            Button { viewModel.showColorAdjust(wallpaper) } label: {
                                Label("色彩调节", systemImage: "slider.horizontal.3")
                            }
                            Divider()
                            Button { toggleFavorite(wallpaper) } label: {
                                Label(wallpaper.isFavorite ? "取消收藏" : "加入收藏", systemImage: wallpaper.isFavorite ? "heart.slash" : "heart")
                            }
                        }
                }
            }
        }
    }
    
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
            ZStack {
                if let thumbData = try? Data(contentsOf: URL(fileURLWithPath: thumbnailPath)),
                   let nsImage = NSImage(data: thumbData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Color.white.opacity(0.05)
                }
            }
            .frame(width: 220, height: 124) // 16:9
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isActive ? Color.white : Color.white.opacity(0.1), lineWidth: isActive ? 3 : 1)
            )
            .shadow(color: .black.opacity(isActive ? 0.4 : 0), radius: 15)
            .opacity(isActive ? 1.0 : 0.4)
            .scaleEffect(isActive ? 1.05 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct WallpaperGridCard: View {
    let wallpaper: Wallpaper
    let isNew: Bool
    @State private var isHovered = false
    @State private var mouseLocation: CGPoint = .zero
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ZStack {
                RadialGradient(colors: [Theme.accent.opacity(0.25), .clear], center: .center, startRadius: 0, endRadius: 180)
                    .blur(radius: 40)
                    .offset(x: mouseLocation.x - 150, y: mouseLocation.y - 100)
                    .scaleEffect(isHovered ? 1.6 : 0.8)
                    .opacity(isHovered ? 1 : 0)
                
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
                                    .stroke(isHovered ? Color.white.opacity(0.2) : Color.white.opacity(0.08), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(isHovered ? 0.5 : 0.2), radius: isHovered ? 40 : 20, x: 0, y: 10)
                    }
                    
                    if isNew {
                        Text("NEW")
                            .font(.system(size: 9, weight: .black))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Theme.accent)
                            .cornerRadius(6)
                            .padding(16)
                    }
                    
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Text("\(wallpaper.resolution) · \(ByteCountFormatter.string(fromByteCount: wallpaper.fileSize, countStyle: .file))")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Theme.glassHeavy)
                                .cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.1), lineWidth: 1))
                                .padding(16)
                        }
                    }
                }
                .scaleEffect(isHovered ? 1.02 : 1.0)
                .onContinuousHover { phase in
                    switch phase {
                    case .active(let location):
                        mouseLocation = location
                        withAnimation(.easeOut(duration: 0.2)) { isHovered = true }
                    case .ended:
                        withAnimation(.easeOut(duration: 0.5)) { isHovered = false }
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(wallpaper.name)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
                
                HStack(spacing: 8) {
                    Text(wallpaper.tags.first?.name.uppercased() ?? "NATURAL")
                        .foregroundColor(Theme.accent)
                    Text("·")
                    Text(wallpaper.type == .video ? "VIDEO" : "HEIC")
                }
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white.opacity(0.3))
                .tracking(1)
            }
            .padding(.horizontal, 4)
        }
    }
}
