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
    @State private var showLaboratory = false
    @StateObject private var downloadManager = DownloadManager.shared

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
                onSearch: {
                    withAnimation(.gallerySpring) {
                        selectedTab = selectedTab == .wallpaper ? .media : .wallpaper
                    }
                },
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
        .overlay(alignment: .bottomLeading) {
            DownloadProgressOverlay(downloadManager: downloadManager)
        }
        .frame(minWidth: 1200, minHeight: 800)
        .preferredColorScheme(.dark)
        .onChange(of: selectedTab) { _, newValue in
            if newValue == .home {
                exploreSection = nil
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .plumSwitchMainTab)) { notification in
            guard let rawValue = notification.object as? Int,
                  let tab = MainTab(rawValue: rawValue) else { return }
            withAnimation(.gallerySpring) {
                selectedTab = tab
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .plumOpenMainWindow)) { _ in
            NSApp.activate(ignoringOtherApps: true)
            NSApp.windows.first { $0.title == "PlumWallPaper" }?.makeKeyAndOrderFront(nil)
        }
        .onReceive(NotificationCenter.default.publisher(for: .plumOpenLaboratory)) { _ in
            showLaboratory = true
        }
        .sheet(isPresented: $showLaboratory) {
            ShaderEditorView()
                .frame(width: 980, height: 680)
        }
        .onAppear {
            // 确保只初始化一次
            guard !hasInitialized else { return }
            hasInitialized = true
            NSLog("[ContentView] 应用启动，准备初始化数据")
        }
    }
}
