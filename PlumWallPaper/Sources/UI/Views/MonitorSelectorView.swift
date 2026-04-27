import SwiftUI

struct ScreenInfo: Identifiable {
    let id: String
    let name: String
    let resolution: String
    let isMain: Bool
}

struct MonitorSelectorView: View {
    let wallpaper: Wallpaper
    @Environment(\.dismiss) var dismiss
    
    // Mock Screens (后续对接 NSScreen)
    let screens = [
        ScreenInfo(id: "1", name: "Studio Display", resolution: "5120×2880", isMain: true),
        ScreenInfo(id: "2", name: "MacBook Pro Built-in", resolution: "3456×2234", isMain: false)
    ]
    
    @State private var selectedScreenId: String? = nil
    
    var body: some View {
        VStack(spacing: 40) {
            VStack(spacing: 8) {
                Text("选择应用显示器")
                    .font(Theme.Fonts.display(size: 24))
                    .italic()
                Text("为不同的桌面分配专属动态视觉")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.3))
            }
            
            // 拓扑展示区
            HStack(spacing: 40) {
                ForEach(screens) { screen in
                    Button(action: { selectedScreenId = screen.id }) {
                        VStack(spacing: 20) {
                            ZStack {
                                // 模拟显示器
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.black)
                                    .frame(width: screen.isMain ? 200 : 160, height: screen.isMain ? 124 : 100)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(selectedScreenId == screen.id ? Theme.accent : Color.white.opacity(0.1), lineWidth: 2)
                                    )
                                
                                // 壁纸预览图
                                if let thumbData = try? Data(contentsOf: URL(fileURLWithPath: wallpaper.thumbnailPath)),
                                   let nsImage = NSImage(data: thumbData) {
                                    Image(nsImage: nsImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: screen.isMain ? 196 : 156, height: screen.isMain ? 120 : 96)
                                        .cornerRadius(10)
                                        .opacity(selectedScreenId == screen.id ? 1 : 0.4)
                                }
                                
                                if screen.isMain {
                                    VStack {
                                        Spacer()
                                        Text("MAIN")
                                            .font(.system(size: 8, weight: .black))
                                            .padding(.horizontal, 4)
                                            .background(Theme.accent)
                                            .cornerRadius(2)
                                            .padding(.bottom, 8)
                                    }
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
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.vertical, 20)
            
            // 操作区
            VStack(spacing: 12) {
                Button(action: applyToAll) {
                    Text("应用到所有显示器")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
                
                HStack(spacing: 12) {
                    Button(action: { dismiss() }) {
                        Text("取消")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Theme.glassHeavy)
                            .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: applyToSelected) {
                        Text("仅应用到选中")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Theme.glassHeavy)
                            .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(selectedScreenId == nil)
                    .opacity(selectedScreenId == nil ? 0.5 : 1)
                }
            }
        }
        .padding(48)
        .frame(width: 600)
        .background(Theme.bg)
        .onAppear {
            selectedScreenId = screens.first?.id
        }
    }
    
    func applyToSelected() {
        guard let screenId = selectedScreenId, 
              let screen = screens.first(where: { $0.id == screenId }) else { return }
        // TODO: 调用后端 WallpaperEngine.shared.setWallpaper(wallpaper, for: screen)
        dismiss()
    }
    
    func applyToAll() {
        // TODO: 调用后端 WallpaperEngine.shared.setWallpaperToAll(wallpaper)
        dismiss()
    }
}
