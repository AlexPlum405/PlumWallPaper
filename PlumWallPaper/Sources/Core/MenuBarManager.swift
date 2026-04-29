import AppKit

@MainActor
final class MenuBarManager {
    static let shared = MenuBarManager()

    private var statusItem: NSStatusItem?
    private weak var window: NSWindow?

    private init() {}

    func configure(window: NSWindow?) {
        self.window = window
    }

    var isEnabled: Bool {
        statusItem != nil
    }

    func setEnabled(_ enabled: Bool) {
        if enabled {
            guard statusItem == nil else { return }
            let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            item.button?.title = "Plum"
            item.button?.font = NSFont.systemFont(ofSize: 13, weight: .semibold)

            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "打开 PlumWallPaper", action: #selector(openMainWindow), keyEquivalent: ""))
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "退出", action: #selector(quitApp), keyEquivalent: "q"))
            menu.items.forEach { $0.target = self }
            item.menu = menu
            statusItem = item
        } else {
            if let item = statusItem {
                NSStatusBar.system.removeStatusItem(item)
                statusItem = nil
            }
        }
    }

    @objc private func openMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
