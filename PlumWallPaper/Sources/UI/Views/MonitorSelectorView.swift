import SwiftUI

struct ScreenInfo: Identifiable, Hashable {
    let id: String
    let name: String
    let resolution: String
    let isMain: Bool
}

struct MonitorSelectorView: View {
    let wallpaper: Wallpaper
    @Environment(\.dismiss) var dismiss

    let screens = [
        ScreenInfo(id: "1", name: "Studio Display", resolution: "5120×2880", isMain: true),
        ScreenInfo(id: "2", name: "MacBook Pro", resolution: "3456×2234", isMain: false)
    ]

    @State private var selectedScreenId: String? = nil

    var body: some View {
        VStack(spacing: 40) {
            Text("选择应用显示器")
                .font(Theme.Fonts.display(size: 24))
                .italic()

            HStack(spacing: 40) {
                ForEach(screens) { screen in
                    Button(action: { selectedScreenId = screen.id }) {
                        VStack(spacing: 20) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.black)
                                    .frame(width: screen.isMain ? 200 : 160, height: screen.isMain ? 124 : 100)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(selectedScreenId == screen.id ? Theme.accent : Color.white.opacity(0.1), lineWidth: 2)
                                    )

                                if let img = loadThumbnail() {
                                    Image(nsImage: img)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: screen.isMain ? 196 : 156, height: screen.isMain ? 120 : 96)
                                        .cornerRadius(10)
                                        .opacity(selectedScreenId == screen.id ? 1 : 0.4)
                                }
                            }

                            VStack(spacing: 4) {
                                Text(screen.name)
                                    .font(.system(size: 13, weight: .bold))
                                Text(screen.resolution)
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.3))
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            VStack(spacing: 12) {
                Button("应用到所有显示器") {
                    // TODO: 调用后端 WallpaperEngine 应用到所有屏幕
                    dismiss()
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.white)
                .foregroundColor(.black)
                .cornerRadius(12)
                .buttonStyle(.plain)

                Button("仅应用到选中") {
                    guard selectedScreenId != nil else { return }
                    // TODO: 调用后端 WallpaperEngine 应用到指定屏幕
                    dismiss()
                }
                .disabled(selectedScreenId == nil)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Theme.glassHeavy)
                .cornerRadius(12)
                .buttonStyle(.plain)

                Button("取消") {
                    dismiss()
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .foregroundColor(.white.opacity(0.5))
                .buttonStyle(.plain)
            }
        }
        .padding(48)
        .frame(width: 600)
        .background(Theme.bg)
        .onAppear { selectedScreenId = screens.first?.id }
    }

    private func loadThumbnail() -> NSImage? {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: wallpaper.thumbnailPath)) else {
            return nil
        }
        return NSImage(data: data)
    }
}
