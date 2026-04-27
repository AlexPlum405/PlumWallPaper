import SwiftUI

struct WallpaperDetailView: View {
    let wallpaper: Wallpaper
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            // 全屏背景
            if let thumbData = try? Data(contentsOf: URL(fileURLWithPath: wallpaper.thumbnailPath)),
               let nsImage = NSImage(data: thumbData) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .edgesIgnoringSafeArea(.all)
            }
            
            // 覆盖层
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .bold))
                            .padding(16)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(40)
                    Spacer()
                }
                
                Spacer()
                
                // 底部信息栏
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(wallpaper.name)
                            .font(Theme.Fonts.display(size: 48))
                            .italic()
                        
                        HStack(spacing: 20) {
                            DetailTag(label: wallpaper.resolution)
                            DetailTag(label: wallpaper.type == .video ? "VIDEO" : "HEIC")
                            DetailTag(label: ByteCountFormatter.string(fromByteCount: wallpaper.fileSize, countStyle: .file))
                        }
                    }
                    Spacer()
                    
                    Button(action: {}) {
                        HStack {
                            Image(systemName: "desktopcomputer")
                            Text("应用为此屏幕壁纸")
                        }
                        .font(.system(size: 14, weight: .bold))
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(80)
                .background(
                    LinearGradient(gradient: Gradient(colors: [.clear, .black.opacity(0.8)]), startPoint: .top, endPoint: .bottom)
                )
            }
        }
    }
}

struct DetailTag: View {
    let label: String
    var body: some View {
        Text(label)
            .font(.system(size: 12, weight: .black))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.white.opacity(0.1))
            .cornerRadius(4)
    }
}
