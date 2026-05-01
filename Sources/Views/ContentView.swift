import SwiftUI
import AppKit

struct ContentView: View {
    @State private var selectedTab: MainTab = .home
    @State private var selectedWallpaper: Wallpaper?

    var body: some View {
        ZStack(alignment: .top) {
            // 1. 全屏沉浸背景 (底层)
            LiquidGlassAtmosphereBackground()

            GrainTextureOverlay(opacity: 0.1)

            // 2. 页面内容 (中层)
            ZStack {
                switch selectedTab {
                case .home:
                    HomeView(selectedWallpaper: $selectedWallpaper)
                case .wallpaper:
                    WallpaperExploreView()
                        .padding(.top, 80)
                case .media:
                    MediaExploreView()
                        .padding(.top, 80)
                case .myLibrary:
                    MyLibraryView()
                        .padding(.top, 80)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // 3. 顶部导航栏 (顶层悬浮)
            TopNavigationBar(
                selectedTab: $selectedTab,
                onOpenSettings: {
                    guard let appDelegate = NSApp.delegate as? AppDelegate else { return }
                    appDelegate.showSettingsWindow(nil)
                },
                onClose: { NSApp.terminate(nil) },
                onMinimize: { NSApp.mainWindow?.miniaturize(nil) },
                onMaximize: { NSApp.mainWindow?.toggleFullScreen(nil) },
                onZoom: { NSApp.mainWindow?.zoom(nil) }
            )
            .zIndex(100)
        }
        .frame(minWidth: 1100, minHeight: 750)
        .preferredColorScheme(.dark)
    }
}
