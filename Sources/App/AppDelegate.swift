// Sources/App/AppDelegate.swift
import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var settingsWindowController: NSWindowController?
    private var statusItem: NSStatusItem?
    private var menuPopover: NSPopover?
    private var runtimeSettingsViewModel: SettingsViewModel?

    func applicationDidFinishLaunching(_ notification: Notification) {
        if let window = NSApplication.shared.windows.first {
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.styleMask.insert(.fullSizeContentView)
            window.isMovableByWindowBackground = true
            window.minSize = NSSize(width: 900, height: 600)
        }

        Task {
            RenderPipeline.shared.setupRenderers()
            let context = PlumWallPaperApp.sharedModelContainer.mainContext
            let settingsViewModel = SettingsViewModel()
            settingsViewModel.configure(modelContext: context)
            runtimeSettingsViewModel = settingsViewModel
            setupMenuBar(visible: settingsViewModel.settings?.menuBarEnabled ?? true)

            await RestoreManager.shared.restoreSession(
                context: context,
                displayManager: DisplayManager.shared
            )
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
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        settingsWindow.title = "设置"
        settingsWindow.titlebarAppearsTransparent = true
        settingsWindow.titleVisibility = .hidden
        settingsWindow.isMovableByWindowBackground = true
        
        // ✅ 隐藏红绿灯按钮
        settingsWindow.standardWindowButton(.closeButton)?.isHidden = true
        settingsWindow.standardWindowButton(.miniaturizeButton)?.isHidden = true
        settingsWindow.standardWindowButton(.zoomButton)?.isHidden = true
        
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
            menuPopover = nil
            return
        }

        if statusItem == nil {
            let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            item.button?.image = NSImage(systemSymbolName: "sparkles.rectangle.stack", accessibilityDescription: "PlumWallPaper")
            item.button?.imagePosition = .imageOnly
            item.button?.target = self
            item.button?.action = #selector(toggleMenuPopover(_:))
            statusItem = item
        }

        if menuPopover == nil {
            let popover = NSPopover()
            popover.behavior = .transient
            popover.contentSize = NSSize(width: 360, height: 620)
            popover.contentViewController = NSHostingController(
                rootView: MenuBarView()
                    .preferredColorScheme(.dark)
            )
            menuPopover = popover
        }
    }

    @objc private func toggleMenuPopover(_ sender: Any?) {
        setupMenuBar(visible: true)
        guard let button = statusItem?.button, let popover = menuPopover else { return }
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: false)
        }
    }

    @objc private func handleMenuBarVisibilityChange(_ notification: Notification) {
        let visible = notification.object as? Bool ?? true
        setupMenuBar(visible: visible)
    }

    @objc private func handleOpenMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first(where: { $0.title == "PlumWallPaper" }) ?? NSApp.windows.first {
            window.makeKeyAndOrderFront(nil)
        }
    }
}
