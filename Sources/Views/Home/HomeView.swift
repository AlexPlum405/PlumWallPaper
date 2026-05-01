import SwiftUI

// MARK: - HomeView (Step 3 极致沉浸版)
struct HomeView: View {
    @Binding var selectedWallpaper: Wallpaper?
    
    @State var currentHeroIndex = 0
    @State private var timer = Timer.publish(every: 8, on: .main, in: .common).autoconnect()
    
    let heroItems = [
        HeroMockItem(
            title: "星际穿越的孤独", 
            subtitle: "4K · 动态 · 512MB", 
            category: "科幻", 
            imageURL: "https://images.unsplash.com/photo-1464802686167-b939a67a06a1?q=80&w=2000",
            color: Color(hex: "1a1a2e")
        ),
        HeroMockItem(
            title: "京都的雨夜", 
            subtitle: "8K · 静态 · 15MB", 
            category: "城市", 
            imageURL: "https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?q=80&w=2000",
            color: Color(hex: "D0104C")
        ),
        HeroMockItem(
            title: "赛博朋克 2077", 
            subtitle: "4K · 动态 · 890MB", 
            category: "游戏", 
            imageURL: "https://images.unsplash.com/photo-1605810230434-7631ac76ec81?q=80&w=2000",
            color: Color(hex: "A52175")
        ),
        HeroMockItem(
            title: "极简雪山", 
            subtitle: "5K · 静态 · 10MB", 
            category: "自然", 
            imageURL: "https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?q=80&w=2000",
            color: Color(hex: "8B5CF6")
        )
    ]

    @State var showingDetail = false
    @State var detailWallpaper: Wallpaper?
    @State var currentDetailIndex: Int = 0

    var body: some View {
        ScrollView(showsIndicators: false) {
            ZStack(alignment: .top) {
                // 1. Hero 轮播区
                heroCarouselSection

                // 2. 内容分区区
                VStack(spacing: 40) {
                    Color.clear.frame(height: 520)

                    VStack(alignment: .leading, spacing: 32) {
                        HomeSection(title: "最新壁纸") {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 20) {
                                    ForEach(0..<8) { i in
                                        WallpaperCard(wallpaper: createMockWallpaper(index: i, isDynamic: false)) {
                                            currentDetailIndex = i
                                            showDetail(for: i, isDynamic: false)
                                        }
                                        .frame(width: 200)
                                    }
                                }
                                .padding(.horizontal, 48)
                            }
                        }

                        HomeSection(title: "热门动态壁纸") {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 20) {
                                    ForEach(8..<16) { i in
                                        WallpaperCard(wallpaper: createMockWallpaper(index: i, isDynamic: true)) {
                                            currentDetailIndex = i
                                            showDetail(for: i, isDynamic: true)
                                        }
                                        .frame(width: 200)
                                    }
                                }
                                .padding(.horizontal, 48)
                            }
                        }
                    }
                    .padding(.bottom, 60)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .onReceive(timer) { _ in
            withAnimation(.easeInOut(duration: 1.2)) {
                currentHeroIndex = (currentHeroIndex + 1) % heroItems.count
            }
        }
        .sheet(item: $detailWallpaper) { wallpaper in
            WallpaperDetailView(
                wallpaper: wallpaper,
                onPrevious: {
                    navigateDetail(direction: -1)
                },
                onNext: {
                    navigateDetail(direction: 1)
                }
            )
        }
    }

    // MARK: - Hero Carousel
    private var heroCarouselSection: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottomLeading) {
                // 背景图层
                ZStack {
                    ForEach(0..<heroItems.count, id: \.self) { index in
                        if index == currentHeroIndex {
                            AsyncImage(url: URL(string: heroItems[index].imageURL)) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: geo.size.width, height: 680) // 增加高度覆盖标题栏
                                        .clipped()
                                        .transition(.opacity.combined(with: .scale(scale: 1.02)))
                                case .failure:
                                    Rectangle().fill(heroItems[index].color.gradient)
                                default:
                                    Rectangle().fill(Color.black)
                                        .overlay(ProgressView().tint(.white))
                                }
                            }
                        }
                    }
                }
                
                // 遮罩层
                VStack {
                    Spacer()
                    ZStack {
                        LinearGradient(
                            colors: [.clear, .black.opacity(0.15), .black.opacity(0.5), .black],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                    .frame(height: 380)
                }

                // 文案信息
                VStack(alignment: .leading, spacing: 18) {
                    Text(heroItems[currentHeroIndex].category.uppercased())
                        .font(.system(size: 13, weight: .bold))
                        .tracking(2.5)
                        .foregroundStyle(.white.opacity(0.8))
                        .id("eyebrow-\(currentHeroIndex)")
                    
                    Text(heroItems[currentHeroIndex].title)
                        .font(.system(size: 48, weight: .bold, design: .serif))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                        .id("title-\(currentHeroIndex)")
                    
                    Text(heroItems[currentHeroIndex].subtitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                        .id("sub-\(currentHeroIndex)")
                    
                    HStack(spacing: 16) {
                        Button(action: {}) {
                            HStack(spacing: 10) {
                                Image(systemName: "play.fill")
                                Text("立即查看")
                                    .font(.system(size: 15, weight: .bold))
                            }
                            .padding(.horizontal, 28)
                            .frame(height: 48)
                            .background(
                                Capsule()
                                    .fill(LinearGradient(colors: [LiquidGlassColors.primaryPink, Color(hex: "A52175")], startPoint: .leading, endPoint: .trailing))
                            )
                        }
                        .buttonStyle(.plain)

                        Button(action: { nextHero() }) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 18, weight: .bold))
                                .frame(width: 48, height: 48)
                                .background(Circle().fill(.white.opacity(0.12)))
                                .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 0.5))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 10)
                }
                .padding(.leading, 100)
                .padding(.bottom, 180) // 再次调高文案位置
                
                // 指示器
                HStack(spacing: 10) {
                    ForEach(0..<heroItems.count, id: \.self) { index in
                        Capsule()
                            .fill(index == currentHeroIndex ? Color.white : Color.white.opacity(0.3))
                            .frame(width: index == currentHeroIndex ? 20 : 8, height: 8)
                    }
                }
                .padding(.leading, 100)
                .padding(.bottom, 140)
            }
            .frame(width: geo.size.width, height: 680)
        }
        .frame(height: 680)
    }
    
}

// MARK: - HeroMockItem
struct HeroMockItem {
    let title: String
    let subtitle: String
    let category: String
    let imageURL: String
    let color: Color
}

// MARK: - HomeSection
struct HomeSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                Button(action: {}) {
                    HStack(spacing: 4) {
                        Text("查看全部")
                            .font(.system(size: 13, weight: .medium))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(.white.opacity(0.5))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 48)

            content
        }
    }
}

// MARK: - MockShelfCard
struct MockShelfCard: View {
    let index: Int
    var isDynamic: Bool = false
    @State private var isHovered = false

    private let gradients: [LinearGradient] = [
        LinearGradient(colors: [Color(hex: "FF3366"), Color(hex: "A52175")], startPoint: .topLeading, endPoint: .bottomTrailing),
        LinearGradient(colors: [Color(hex: "667EEA"), Color(hex: "764BA2")], startPoint: .topLeading, endPoint: .bottomTrailing),
        LinearGradient(colors: [Color(hex: "F093FB"), Color(hex: "F5576C")], startPoint: .topLeading, endPoint: .bottomTrailing),
        LinearGradient(colors: [Color(hex: "4FACFE"), Color(hex: "00F2FE")], startPoint: .topLeading, endPoint: .bottomTrailing),
        LinearGradient(colors: [Color(hex: "43E97B"), Color(hex: "38F9D7")], startPoint: .topLeading, endPoint: .bottomTrailing),
        LinearGradient(colors: [Color(hex: "FA709A"), Color(hex: "FEE140")], startPoint: .topLeading, endPoint: .bottomTrailing),
        LinearGradient(colors: [Color(hex: "30CFD0"), Color(hex: "330867")], startPoint: .topLeading, endPoint: .bottomTrailing),
        LinearGradient(colors: [Color(hex: "A8EDEA"), Color(hex: "FED6E3")], startPoint: .topLeading, endPoint: .bottomTrailing),
        LinearGradient(colors: [Color(hex: "FF9A56"), Color(hex: "FF6A88")], startPoint: .topLeading, endPoint: .bottomTrailing)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(gradients[index % gradients.count])
                    .frame(width: 200, height: 130)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(isHovered ? 0.3 : 0.1), lineWidth: 1)
                    )

                if isDynamic {
                    Text("0:\(30 + index % 30)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(.black.opacity(0.5)))
                        .padding(8)
                }
            }

            Text("壁纸 #\(index + 1)")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)

            Text(isDynamic ? "动态 · 4K" : "静态 · 5K")
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.5))
        }
        .scaleEffect(isHovered ? 1.03 : 1.0)
        .animation(.easeOut(duration: 0.2), value: isHovered)
        .onHover { isHovered = $0 }
    }
}
