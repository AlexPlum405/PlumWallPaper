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
            // TODO: cycle wallpaper list when playlist support is added
        }
        GlobalShortcutManager.shared.onPrevWallpaper = {
            // TODO: cycle wallpaper list when playlist support is added
        }
        GlobalShortcutManager.shared.onTogglePlayback = {
            WallpaperEngine.shared.pauseAll()
        }
        GlobalShortcutManager.shared.onToggleMute = {
            // TODO: add global audio mute integration
        }
        GlobalShortcutManager.shared.onShowWindow = {
            NSApp.activate(ignoringOtherApps: true)
            NSApp.windows.first?.makeKeyAndOrderFront(nil)
        }
        GlobalShortcutManager.shared.onToggleFavorite = {
            // TODO: bind to current selected wallpaper in app state
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
