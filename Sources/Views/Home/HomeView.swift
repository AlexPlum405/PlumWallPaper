import SwiftUI

// MARK: - Artisan Monograph HomeView (Scheme C: Interactive Fix)
struct HomeView: View {
    struct HeroItem: Identifiable {
        let id = UUID()
        let title: String
        let category: String
        let imageURL: String
    }

    @Binding var selectedWallpaper: Wallpaper?
    @State var currentHeroIndex = 0
    @State private var timer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()
    @State private var isApplying = false
    @State var currentDetailIndex: Int = 0
    
    let heroItems: [HeroItem] = [
        HeroItem(title: "星际穿越的孤独", category: "CURATED EXHIBITION", imageURL: "https://images.unsplash.com/photo-1464802686167-b939a67a06a1?q=80&w=2000"),
        HeroItem(title: "京都的雨夜", category: "CITYSCAPE SERIES", imageURL: "https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?q=80&w=2000"),
        HeroItem(title: "赛博朋克 2077", category: "NEON DREAMS", imageURL: "https://images.unsplash.com/photo-1605810230434-7631ac76ec81?q=80&w=2000")
    ]

    @State var detailWallpaper: Wallpaper?
    private let mainPadding: CGFloat = 88

    var body: some View {
        GeometryReader { windowGeo in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // 使用 GeometryProxy 确定的宽度，不再硬编码 NSScreen
                    artisanFullscreenHero(size: windowGeo.size)
                    
                    VStack(alignment: .leading, spacing: 100) {
                        artisanSection(title: "最新画作", meta: "NEW ACQUISITIONS", range: 0..<8, isDynamic: false)
                        artisanSection(title: "热门动态", meta: "KINETIC ART", range: 8..<16, isDynamic: true)
                    }
                    .padding(.top, 100).padding(.bottom, 160)
                    .background(LiquidGlassColors.deepBackground)
                }
            }
        }
        .onReceive(timer) { _ in
            if !isApplying {
                withAnimation(.galleryEase) {
                    currentHeroIndex = (currentHeroIndex + 1) % heroItems.count
                }
            }
        }
        .sheet(item: $detailWallpaper) { wallpaper in
            WallpaperDetailView(wallpaper: wallpaper, onPrevious: { navigateDetail(direction: -1) }, onNext: { navigateDetail(direction: 1) })
        }
    }

    private func artisanFullscreenHero(size: CGSize) -> some View {
        ZStack(alignment: .bottomLeading) {
            ZStack {
                let itemsArray = Array(heroItems.enumerated())
                ForEach(itemsArray, id: \.element.id) { index, item in
                    if index == currentHeroIndex {
                        AsyncImage(url: URL(string: item.imageURL)) { phase in
                            if let image = phase.image {
                                image.resizable().aspectRatio(contentMode: .fill)
                                    .transition(.opacity.combined(with: .scale(scale: 1.02)))
                            } else { Color.black }
                        }
                    }
                }
            }
            .frame(width: size.width, height: size.height).clipped()
            
            LinearGradient(colors: [.clear, LiquidGlassColors.deepBackground.opacity(0.8), LiquidGlassColors.deepBackground], startPoint: .init(x: 0.5, y: 0.7), endPoint: .bottom).frame(height: 300)
            
            VStack(alignment: .leading, spacing: 14) {
                Text(heroItems[currentHeroIndex].category).font(.system(size: 9, weight: .black)).kerning(4).foregroundStyle(LiquidGlassColors.primaryPink)
                Text(heroItems[currentHeroIndex].title).font(.custom("Georgia", size: 44).bold()).foregroundStyle(.white)
                
                HStack(spacing: 24) {
                    Button(action: { 
                        isApplying = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { isApplying = false }
                    }) {
                        HStack(spacing: 12) {
                            if isApplying { CustomProgressView(tint: .white, scale: 0.8) }
                            else { Image(systemName: "macwindow.on.rectangle").font(.system(size: 14)); Text("设为壁纸").font(.system(size: 13, weight: .bold)).kerning(1.5) }
                        }
                        .padding(.horizontal, 32).frame(height: 44).background(Capsule().fill(LiquidGlassColors.primaryPink)).artisanShadow(color: LiquidGlassColors.primaryPink.opacity(0.3), radius: 15)
                    }.buttonStyle(.plain)
                    
                    HStack(spacing: 8) {
                        ForEach(0..<heroItems.count, id: \.self) { index in
                            Circle().fill(index == currentHeroIndex ? Color.white : Color.white.opacity(0.2)).frame(width: 5, height: 5)
                        }
                    }
                }
            }
            .padding(.leading, mainPadding).padding(.bottom, 100)
            
            VStack { Spacer(); Image(systemName: "chevron.compact.down").font(.system(size: 32, weight: .ultraLight)).foregroundStyle(Color.white.opacity(0.3)).padding(.bottom, 30) }.frame(maxWidth: .infinity)
        }
        .frame(height: size.height)
    }

    private func artisanSection(title: String, meta: String, range: Range<Int>, isDynamic: Bool) -> some View {
        VStack(alignment: .leading, spacing: 32) {
            VStack(alignment: .leading, spacing: 8) {
                Text(meta).font(.system(size: 9, weight: .black)).kerning(3).foregroundStyle(LiquidGlassColors.primaryPink)
                HStack(alignment: .firstTextBaseline) {
                    Text(title).font(.custom("Georgia", size: 28).bold())
                    Rectangle().fill(LiquidGlassColors.glassBorder.opacity(0.2)).frame(width: 80, height: 0.5).padding(.leading, 16)
                    Spacer()
                    Button("VIEW ALL") { }.font(.system(size: 10, weight: .black)).kerning(2).foregroundStyle(LiquidGlassColors.textQuaternary).buttonStyle(.plain)
                }
            }.padding(.horizontal, mainPadding)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 32) {
                    ForEach(range, id: \.self) { i in
                        WallpaperCard(wallpaper: createMockWallpaper(index: i, isDynamic: isDynamic)) {
                            currentDetailIndex = i
                            detailWallpaper = createMockWallpaper(index: i, isDynamic: isDynamic)
                        }
                    }
                }.padding(.horizontal, mainPadding).padding(.bottom, 20)
            }
        }
    }
}
