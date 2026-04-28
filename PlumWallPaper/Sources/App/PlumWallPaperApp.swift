//
//  PlumWallPaperApp.swift
//  PlumWallPaper
//
//  Created on 2026-04-28.
//

import SwiftUI
import SwiftData

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
    }

    var body: some Scene {
        WindowGroup {
            WebViewContainer(viewModel: viewModel, modelContext: modelContainer.mainContext)
                .frame(minWidth: 1200, minHeight: 800)
                .task {
                    await viewModel.restoreLastSession(context: modelContainer.mainContext)
                }
        }
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
