// Sources/App/AppDelegate.swift
import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var settingsWindowController: NSWindowController?
    private var statusItem: NSStatusItem?
    private var statusMenu: NSMenu?
    private var runtimeSettingsViewModel: SettingsViewModel?

    var mainWindow: NSWindow?
    var windowDelegate: MainWindowDelegate?

    func applicationDidFinishLaunching(_ notification: Notification) {
        if let window = NSApplication.shared.windows.first {
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.styleMask.insert(.fullSizeContentView)
            window.isMovableByWindowBackground = true
            window.minSize = NSSize(width: 900, height: 600)
        }

        // 关键服务立即初始化
        Task {
            RenderPipeline.shared.setupRenderers()
            let context = PlumWallPaperApp.sharedModelContainer.mainContext
            let settingsViewModel = SettingsViewModel()
            settingsViewModel.configure(modelContext: context)
            runtimeSettingsViewModel = settingsViewModel
            setupMenuBar(visible: settingsViewModel.settings?.menuBarEnabled ?? true)

            _ = SuperResolutionService.shared
            _ = VideoEnhancementService.shared

            await RestoreManager.shared.restoreSession(
                context: context,
                displayManager: DisplayManager.shared
            )
        }

        // 非关键服务延迟初始化（优化启动速度）
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            PerformanceMonitor.shared.startMonitoring()
            // 清理旧的磁盘缓存
            Task {
                RemoteThumbnailImageCache.shared.cleanDiskCache(olderThan: 30)
            }
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMenuBarVisibilityChange(_:)),
            name: .plumMenuBarVisibilityChanged,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleOpenMainWindow),
            name: .plumOpenMainWindow,
            object: nil
        )
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    // MARK: - 设置窗口

    @objc func showSettingsWindow(_ sender: Any?) {
        if let settingsWindow = settingsWindowController?.window {
            settingsWindow.makeKeyAndOrderFront(nil)
            settingsWindow.orderFrontRegardless()
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let settingsWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 550),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        settingsWindow.isMovableByWindowBackground = true
        
        settingsWindow.backgroundColor = .clear
        settingsWindow.hasShadow = true
        settingsWindow.appearance = NSAppearance(named: .vibrantDark) // ✅ 强制深色
        settingsWindow.minSize = NSSize(width: 800, height: 550)
        settingsWindow.isReleasedWhenClosed = false
        settingsWindow.center()

        settingsWindow.contentView = EdgeToEdgeHostingView(
            rootView: SettingsView()
                .preferredColorScheme(.dark) // ✅ 强制 SwiftUI 视图为深色
                .modelContainer(PlumWallPaperApp.sharedModelContainer)
        )

        let controller = NSWindowController(window: settingsWindow)
        settingsWindowController = controller
        controller.showWindow(nil)
        settingsWindow.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Menu Bar

    private func setupMenuBar(visible: Bool) {
        if !visible {
            if let statusItem {
                NSStatusBar.system.removeStatusItem(statusItem)
            }
            statusItem = nil
            statusMenu = nil
            return
        }

        if statusItem == nil {
            let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            if let appIcon = NSApp.applicationIconImage {
                let smallIcon = NSImage(size: NSSize(width: 18, height: 18))
                smallIcon.lockFocus()
                appIcon.draw(in: NSRect(x: 0, y: 0, width: 18, height: 18))
                smallIcon.unlockFocus()
                item.button?.image = smallIcon
            } else {
                item.button?.image = NSImage(systemSymbolName: "sparkles.rectangle.stack", accessibilityDescription: "PlumWallPaper")
            }
            item.button?.imagePosition = .imageOnly
            statusItem = item
        }

        if statusMenu == nil {
            let menu = NSMenu()

            // 状态显示
            let statusItem = NSMenuItem(title: "PlumWallPaper", action: nil, keyEquivalent: "")
            statusItem.isEnabled = false
            menu.addItem(statusItem)

            menu.addItem(NSMenuItem.separator())

            // 主要操作
            menu.addItem(NSMenuItem(title: "显示主窗口", action: #selector(handleOpenMainWindow), keyEquivalent: "o"))

            menu.addItem(NSMenuItem.separator())

            // 底部操作
            menu.addItem(NSMenuItem(title: "退出", action: #selector(quitApp), keyEquivalent: "q"))

            statusMenu = menu
            self.statusItem?.menu = menu
        }
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    @objc private func handleMenuBarVisibilityChange(_ notification: Notification) {
        let visible = notification.object as? Bool ?? true
        setupMenuBar(visible: visible)
    }

    @objc private func handleOpenMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        if let window = mainWindow {
            window.makeKeyAndOrderFront(nil)
        }
    }
}

// 窗口委托：让窗口关闭时只隐藏而不是真正关闭
class MainWindowDelegate: NSObject, NSWindowDelegate {
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        return false
    }
}
