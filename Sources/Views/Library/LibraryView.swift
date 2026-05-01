import SwiftUI

struct LibraryView: View {
    @Binding var selectedWallpaper: Wallpaper?
    @State private var searchText = ""
    
    // Mock 数据
    let mockWallpapers = (1...12).map { i in
        Wallpaper(name: "动态壁纸 \(i)", 
                 filePath: "", 
                 type: .video, 
                 resolution: "3840x2160",
                 isFavorite: i % 3 == 0)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 32) {
                // 顶部标题与搜索
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("壁纸库")
                            .font(.system(size: 42, weight: .bold))
                            .foregroundStyle(.white)
                        
                        Text("探索无限可能的动态桌面")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    
                    Spacer()
                    
                    // 悬浮感的搜索框
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

                // 真正的 WaifuX 风格网格
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 260, maximum: 400), spacing: 24)], spacing: 28) {
                    ForEach(mockWallpapers) { wp in
                        WallpaperCard(wallpaper: wp) {
                            selectedWallpaper = wp
                        }
                    }
                }
                .padding(.horizontal, 48)
            }
            .padding(.bottom, 60)
        }
    }
}
