import SwiftUI
import AppKit

// MARK: - Explore Section Context
enum ExploreSection {
    case latestStills
    case popularMotions
}

// MARK: - Artisan Gallery Container (Scheme C: Interactive Fix)
struct ContentView: View {
    @State private var selectedTab: MainTab = .home
    @State private var selectedWallpaper: Wallpaper?
    @State private var hasInitialized = false
    @State private var exploreSection: ExploreSection?

    var body: some View {
        ZStack(alignment: .top) {
            // 1. 统一底层背景
            LiquidGlassAtmosphereBackground()
            GrainTextureOverlay(opacity: 0.08)

            // 2. 动态内容区
            Group {
                switch selectedTab {
                case .home:
                    HomeView(
                        selectedWallpaper: $selectedWallpaper,
                        onSwitchToWallpaperTab: {
                            exploreSection = .latestStills
                            selectedTab = .wallpaper
                        },
                        onSwitchToMediaTab: {
                            exploreSection = .popularMotions
                            selectedTab = .media
                        }
                    )
                case .wallpaper:
                    WallpaperExploreView()
                case .media:
                    MediaExploreView()
                case .myLibrary:
                    MyLibraryView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .ignoresSafeArea() // 统一全屏处理
        // 3. 核心修复：使用 overlay 挂载导航栏，确保 100% 可点击
        .overlay(alignment: .top) {
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
            .padding(.top, 0) // 在 overlay 中已经脱离了主布局流
        }
        .frame(minWidth: 1200, minHeight: 800)
        .preferredColorScheme(.dark)
        .onChange(of: selectedTab) { _, newValue in
            if newValue == .home {
                exploreSection = nil
            }
        }
        .onAppear {
            // 确保只初始化一次
            guard !hasInitialized else { return }
            hasInitialized = true
            NSLog("[ContentView] 应用启动，准备初始化数据")
        }
    }
}
