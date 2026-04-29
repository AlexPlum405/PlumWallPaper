//
//  PlumWallPaperApp.swift
//  PlumWallPaper
//
//  Created on 2026-04-28.
//

import SwiftUI
import SwiftData
import ServiceManagement

@main
struct PlumWallPaperApp: App {
    let modelContainer: ModelContainer
    @State private var viewModel = AppViewModel()

    init() {
        do {
            let schema = Schema([
                Wallpaper.self,
                Tag.self,
                FilterPreset.self,
                Settings.self
            ])
            let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }

        GlobalShortcutManager.shared.onNextWallpaper = {
            // 需要轮播功能支持，暂不可用
        }
        GlobalShortcutManager.shared.onPrevWallpaper = {
            // 需要轮播功能支持，暂不可用
        }
        GlobalShortcutManager.shared.onTogglePlayback = {
            PauseStrategyManager.shared.toggleManualPause()
        }
        GlobalShortcutManager.shared.onToggleMute = {
            WallpaperEngine.shared.toggleMuteAll()
        }
        GlobalShortcutManager.shared.onShowWindow = {
            NSApp.activate(ignoringOtherApps: true)
            NSApp.windows.first?.makeKeyAndOrderFront(nil)
        }
        GlobalShortcutManager.shared.onToggleFavorite = {
            // 需要 WebBridge 通知前端当前选中壁纸，暂不可用
        }
        GlobalShortcutManager.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            WebViewContainer(viewModel: viewModel, modelContext: modelContainer.mainContext)
                .frame(minWidth: 1200, minHeight: 800)
                .ignoresSafeArea(.all)
                .task {
                    await viewModel.restoreLastSession(context: modelContainer.mainContext)
                }
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .appTermination) {
                Button("退出 PlumWallPaper") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q")
            }
        }
    }
}
