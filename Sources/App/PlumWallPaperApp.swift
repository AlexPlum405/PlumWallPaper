// Sources/App/PlumWallPaperApp.swift
import SwiftUI
import SwiftData
import AppKit

@main
struct PlumWallPaperApp {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate

        // 创建主窗口
        let contentView = ContentView()
            .modelContainer(sharedModelContainer)

        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: NSSize(width: 1200, height: 800)),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        window.title = "PlumWallPaper"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.minSize = NSSize(width: 1100, height: 750)
        window.center() // 确保窗口在屏幕正中间

        // 保留系统红绿灯按钮（不隐藏）

        // 使用 EdgeToEdgeHostingView 强制零安全区域
        let hostingView = EdgeToEdgeHostingView(rootView: contentView)
        window.contentView = hostingView

        window.makeKeyAndOrderFront(nil)
        app.activate(ignoringOtherApps: true)
        app.run()
    }

    static var sharedModelContainer: ModelContainer = {
        let schema = Schema([Wallpaper.self, Tag.self, ShaderPreset.self, Settings.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            print("❌ SwiftData 初始化失败: \(error)")
            let memoryConfig = ModelConfiguration(isStoredInMemoryOnly: true)
            return try! ModelContainer(for: schema, configurations: [memoryConfig])
        }
    }()
}
