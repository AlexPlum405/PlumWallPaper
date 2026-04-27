import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppViewModel.self) private var viewModel
    @Query(sort: \Wallpaper.importDate, order: .reverse) private var wallpapers: [Wallpaper]
    
    @State private var activeId: UUID? = nil
    
    var activeWallpaper: Wallpaper? {
        if let id = activeId {
            return wallpapers.first(where: { $0.id == id })
        }
        return wallpapers.first
    }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                // --- Hero Section (极致沉浸) ---
                ZStack(alignment: .bottomLeading) {
                    // 背景
                    Group {
                        if let wallpaper = activeWallpaper,
                           let thumbData = try? Data(contentsOf: URL(fileURLWithPath: wallpaper.thumbnailPath)),
                           let nsImage = NSImage(data: thumbData) {
                            Image(nsImage: nsImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            Color.black
                        }
                    }
                    .frame(height: 720)
                    .clipped()
                    .overlay(
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0),
                                .init(color: Theme.bg.opacity(0.8), location: 0.6),
                                .init(color: Theme.bg, location: 1.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    // 信息层
                    if let wallpaper = activeWallpaper {
                        VStack(alignment: .leading, spacing: 28) {
                            Text(wallpaper.tags.first?.name.uppercased() ?? "PREMIUM")
                                .font(.system(size: 11, weight: .black))
                                .tracking(3)
                                .foregroundColor(Theme.accent)
                            
                            Text(wallpaper.name)
                                .font(Theme.Fonts.display(size: 84))
                                .italic()
                                .lineLimit(1)
                                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                            
                            HStack(spacing: 24) {
                                Label(wallpaper.resolution, systemImage: "video.fill")
                                Label(ByteCountFormatter.string(fromByteCount: wallpaper.fileSize, countStyle: .file), systemImage: "sdcard.fill")
                                if let duration = wallpaper.duration {
                                    Label(formatDuration(duration), systemImage: "clock.fill")
                                }
                            }
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white.opacity(0.35))
                            
                            HStack(spacing: 16) {
                                Button(action: { setWallpaper(wallpaper) }) {
                                    Text("设为壁纸")
                                        .font(.system(size: 14, weight: .bold))
                                        .padding(.horizontal, 36)
                                        .padding(.vertical, 14)
                                        .background(Color.white)
                                        .foregroundColor(.black)
                                        .cornerRadius(12)
                                        .shadow(color: .white.opacity(0.2), radius: 20, x: 0, y: 10)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Button(action: { toggleFavorite(wallpaper) }) {
                                    Image(systemName: wallpaper.isFavorite ? "heart.fill" : "heart")
                                        .font(.system(size: 18))
                                        .foregroundColor(wallpaper.isFavorite ? Theme.accent : .white)
                                        .padding(14)
                                        .background(Theme.glassHeavy)
                                        .plumGlass(cornerRadius: 12)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.leading, 80)
                        .padding(.bottom, 200)
                    }
                    
                    // --- 物理判定缩略图条 ---
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            ForEach(wallpapers.prefix(10)) { w in
                                ThumbCard(
                                    thumbnailPath: w.thumbnailPath,
                                    isActive: (activeId ?? wallpapers.first?.id) == w.id,
                                    onSelect: { activeId = w.id }
                                )
                            }
                        }
                        .padding(.horizontal, 80)
                    }
                    .padding(.bottom, 48)
                }
                .frame(height: 720)
                
                // --- Grid Section ---
                VStack(alignment: .leading, spacing: 40) {
                    HStack(alignment: .lastTextBaseline) {
                        Text("最近添加")
                            .font(Theme.Fonts.display(size: 36))
                        Spacer()
                        Text("查看全部")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Theme.accent)
                    }
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 320), spacing: 32)], spacing: 40) {
                        ForEach(wallpapers.prefix(8)) { wallpaper in
                            WallpaperGridCard(wallpaper: wallpaper)
                        }
                    }
                }
                .padding(80)
                .background(Theme.bg)
            }
        }
        .background(Theme.bg)
        .edgesIgnoringSafeArea(.all)
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

struct ThumbCard: View {
    let thumbnailPath: String
    let isActive: Bool
    let onSelect: () -> Void
    
    @State private var dragDistance: CGFloat = 0
    
    var body: some View {
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
        .frame(width: 220, height: 124)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isActive ? Color.white : Color.clear, lineWidth: 2)
        )
        .shadow(color: isActive ? .white.opacity(0.1) : .clear, radius: 20)
        .opacity(isActive ? 1 : 0.4)
        .scaleEffect(isActive ? 1.02 : 1.0)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { val in dragDistance = sqrt(pow(val.translation.width, 2) + pow(val.translation.height, 2)) }
                .onEnded { _ in
                    if dragDistance < 5 {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { onSelect() }
                    }
                    dragDistance = 0
                }
        )
    }
}

struct WallpaperGridCard: View {
    let wallpaper: Wallpaper
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ZStack {
                if let thumbData = try? Data(contentsOf: URL(fileURLWithPath: wallpaper.thumbnailPath)),
                   let nsImage = NSImage(data: thumbData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity)
                        .aspectRatio(16/9, contentMode: .fit)
                        .cornerRadius(18)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(isHovered ? Color.white.opacity(0.2) : Theme.border, lineWidth: 1)
                        )
                }
                
                Image(systemName: "play.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
                    .opacity(isHovered ? 0.8 : 0.15)
                    .scaleEffect(isHovered ? 1.1 : 1.0)
            }
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
            .onHover { isHovered = $0 }
            
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(wallpaper.name)
                        .font(.system(size: 16, weight: .bold))
                    Text("\(wallpaper.resolution) · \(wallpaper.type == .video ? "VIDEO" : "HEIC")")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(.white.opacity(0.3))
                }
                Spacer()
                Image(systemName: "ellipsis")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white.opacity(0.2))
            }
        }
    }
}
