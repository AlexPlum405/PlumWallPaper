//
//  HomeView.swift
//  PlumWallPaper
//
//  Created on 2026-04-28.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Wallpaper.importDate, order: .reverse) private var wallpapers: [Wallpaper]
    @Query(filter: #Predicate<Wallpaper> { $0.isFavorite }) private var favorites: [Wallpaper]

    @State private var activeWallpaper: Wallpaper?
    @State private var dragDistance: CGFloat = 0

    // Mock 数据（开发阶段）
    let mockWallpapers = [
        ("1", "Deep Space Nebula", "8K VIDEO", "https://images.unsplash.com/photo-1462331940025-496dfbfc7564?w=1600"),
        ("2", "Minimalist Peak", "6K HEIC", "https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=1600"),
        ("3", "Cyberpunk Rain", "4K VIDEO", "https://images.unsplash.com/photo-1514565131-fce0801e5785?w=1600"),
        ("4", "Forest Path", "8K HEIC", "https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=1600")
    ]

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                // Hero 展示区
                heroSection

                // 内容网格区
                contentSection
            }
        }
        .background(Theme.bg)
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            // 初始化：如果没有壁纸，设置第一个为活动壁纸
            if activeWallpaper == nil {
                activeWallpaper = wallpapers.first
            }
        }
    }

    // MARK: - Hero Section
    private var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            // 背景壁纸
            if let activeWallpaper = activeWallpaper {
                AsyncImage(url: URL(string: mockWallpapers[0].3)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.black
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
            } else {
                Color.black
                    .frame(height: 720)
            }

            // 信息层
            VStack(alignment: .leading, spacing: 28) {
                // 标签
                Text("SCI-FI · SPACE")
                    .font(.system(size: 11, weight: .black))
                    .tracking(3)
                    .foregroundColor(Theme.accent)

                // 标题
                Text(activeWallpaper?.name ?? "Deep Space Nebula")
                    .font(Theme.Fonts.display(size: 84))
                    .italic()
                    .lineLimit(1)
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)

                // 元数据
                HStack(spacing: 24) {
                    Label(activeWallpaper?.type.displayName ?? "VIDEO", systemImage: "video.fill")
                    Label(activeWallpaper?.formattedFileSize ?? "1.2 GB", systemImage: "sdcard.fill")
                    Label(activeWallpaper?.formattedDuration ?? "00:45", systemImage: "clock.fill")
                }
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white.opacity(0.35))

                // 操作按钮
                HStack(spacing: 16) {
                    Button(action: setAsWallpaper) {
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

                    Button(action: toggleFavorite) {
                        Image(systemName: activeWallpaper?.isFavorite == true ? "heart.fill" : "heart")
                            .font(.system(size: 18))
                            .padding(14)
                            .background(Theme.glassHeavy)
                            .plumGlass(cornerRadius: 12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.leading, 80)
            .padding(.bottom, 200)

            // 缩略图条
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(mockWallpapers, id: \.0) { w in
                        ThumbCard(
                            url: w.3,
                            isActive: w.0 == "1", // TODO: 绑定实际数据
                            onSelect: {
                                // TODO: 切换活动壁纸
                            }
                        )
                    }
                }
                .padding(.horizontal, 80)
            }
            .padding(.bottom, 48)
        }
        .frame(height: 720)
    }

    // MARK: - Content Section
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 40) {
            // 收藏区
            if !favorites.isEmpty {
                sectionHeader(title: "收藏", action: {})
                wallpaperGrid(wallpapers: favorites)
            }

            // 最近添加
            sectionHeader(title: "最近添加", action: {})
            wallpaperGrid(wallpapers: Array(wallpapers.prefix(8)))
        }
        .padding(80)
        .background(Theme.bg)
    }

    private func sectionHeader(title: String, action: @escaping () -> Void) -> some View {
        HStack(alignment: .lastTextBaseline) {
            Text(title)
                .font(Theme.Fonts.display(size: 36))
            Spacer()
            Text("查看全部")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Theme.accent)
                .onTapGesture(perform: action)
        }
    }

    private func wallpaperGrid(wallpapers: [Wallpaper]) -> some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 320), spacing: 32)],
            spacing: 40
        ) {
            ForEach(wallpapers) { wallpaper in
                WallpaperCard(wallpaper: wallpaper)
            }
        }
    }

    // MARK: - Actions
    private func setAsWallpaper() {
        // TODO: 触发多显示器选择弹层
        print("设为壁纸")
    }

    private func toggleFavorite() {
        guard let wallpaper = activeWallpaper else { return }
        wallpaper.isFavorite.toggle()
        try? modelContext.save()
    }
}

// MARK: - Thumb Card
struct ThumbCard: View {
    let url: String
    let isActive: Bool
    let onSelect: () -> Void
    @State private var dragDistance: CGFloat = 0

    var body: some View {
        AsyncImage(url: URL(string: url)) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            Color.white.opacity(0.05)
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
                .onChanged { val in
                    dragDistance = sqrt(pow(val.translation.width, 2) + pow(val.translation.height, 2))
                }
                .onEnded { _ in
                    if dragDistance < 5 {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            onSelect()
                        }
                    }
                    dragDistance = 0
                }
        )
    }
}

// MARK: - Wallpaper Card
struct WallpaperCard: View {
    let wallpaper: Wallpaper
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 缩略图
            ZStack {
                Color.white.opacity(0.02)
                    .aspectRatio(16/9, contentMode: .fit)
                    .cornerRadius(18)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(isHovered ? Color.white.opacity(0.2) : Theme.border, lineWidth: 1)
                    )

                if wallpaper.isVideo {
                    Image(systemName: "play.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                        .opacity(isHovered ? 0.8 : 0.15)
                        .scaleEffect(isHovered ? 1.1 : 1.0)
                }
            }
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
            .onHover { isHovered = $0 }

            // 信息
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(wallpaper.name)
                        .font(.system(size: 16, weight: .bold))
                    Text("\(wallpaper.resolution) · \(wallpaper.type.displayName) · \(wallpaper.formattedFileSize)")
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
