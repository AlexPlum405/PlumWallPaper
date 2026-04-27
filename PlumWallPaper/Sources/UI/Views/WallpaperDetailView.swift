import SwiftUI

struct WallpaperDetailView: View {
    let wallpaper: Wallpaper
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let img = loadThumbnail() {
                Image(nsImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .edgesIgnoringSafeArea(.all)
            }

            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .bold))
                            .padding(16)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .padding(40)
                    Spacer()
                }

                Spacer()

                VStack(alignment: .leading, spacing: 12) {
                    Text(wallpaper.name)
                        .font(Theme.Fonts.display(size: 48))
                        .italic()

                    Button("设为壁纸") {
                        // TODO: 调用后端 WallpaperEngine 设置壁纸
                    }
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(Color.white)
                    .foregroundColor(.black)
                    .cornerRadius(12)
                    .buttonStyle(.plain)
                }
                .padding(80)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
    }

    private func loadThumbnail() -> NSImage? {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: wallpaper.thumbnailPath)) else {
            return nil
        }
        return NSImage(data: data)
    }
}
