import SwiftUI
import SwiftData

struct LibraryView: View {
    @Binding var selectedWallpaper: Wallpaper?
    @Query(sort: \Wallpaper.importDate, order: .reverse) private var wallpapers: [Wallpaper]
    @State private var searchText = ""

    private var filteredWallpapers: [Wallpaper] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return wallpapers }
        return wallpapers.filter { wallpaper in
            wallpaper.name.localizedCaseInsensitiveContains(trimmed)
                || wallpaper.tags.contains { $0.name.localizedCaseInsensitiveContains(trimmed) }
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 32) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("壁纸库")
                            .font(.system(size: 42, weight: .bold))
                            .foregroundStyle(.white)

                        Text("\(wallpapers.count) 件本地艺术品")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white.opacity(0.4))
                    }

                    Spacer()

                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.white.opacity(0.4))
                        TextField("", text: $searchText, prompt: Text("搜索内容...").foregroundColor(.white.opacity(0.25)))
                            .textFieldStyle(.plain)
                            .frame(width: 180)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.06))
                            .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 0.5))
                    )
                }
                .padding(.horizontal, 48)
                .padding(.top, 20)

                if filteredWallpapers.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: searchText.isEmpty ? "photo.stack" : "magnifyingglass")
                            .font(.system(size: 42, weight: .ultraLight))
                            .foregroundStyle(.white.opacity(0.35))
                        Text(searchText.isEmpty ? "暂无本地壁纸" : "没有匹配结果")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 120)
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 260, maximum: 400), spacing: 24)], spacing: 28) {
                        ForEach(filteredWallpapers) { wallpaper in
                            WallpaperCard(wallpaper: wallpaper) {
                                selectedWallpaper = wallpaper
                            }
                        }
                    }
                    .padding(.horizontal, 48)
                }
            }
            .padding(.bottom, 60)
        }
    }
}
