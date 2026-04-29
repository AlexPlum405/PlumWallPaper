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
            let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
            let image = Self.makeTemplateIcon()
            item.button?.image = image

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

    private static func makeTemplateIcon() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size)
        image.lockFocus()

        let plumPath = NSBezierPath()
        plumPath.move(to: NSPoint(x: 9, y: 15.6))
        plumPath.curve(to: NSPoint(x: 15, y: 9.6), controlPoint1: NSPoint(x: 12.2, y: 15.6), controlPoint2: NSPoint(x: 15, y: 12.9))
        plumPath.curve(to: NSPoint(x: 9, y: 2), controlPoint1: NSPoint(x: 15, y: 5.1), controlPoint2: NSPoint(x: 9, y: 2))
        plumPath.curve(to: NSPoint(x: 3, y: 9.6), controlPoint1: NSPoint(x: 9, y: 2), controlPoint2: NSPoint(x: 3, y: 5.1))
        plumPath.curve(to: NSPoint(x: 9, y: 15.6), controlPoint1: NSPoint(x: 3, y: 12.9), controlPoint2: NSPoint(x: 5.8, y: 15.6))
        NSColor.black.setFill()
        plumPath.fill()

        let stemPath = NSBezierPath()
        stemPath.move(to: NSPoint(x: 9, y: 16.2))
        stemPath.line(to: NSPoint(x: 9, y: 18))
        stemPath.lineWidth = 1.6
        stemPath.lineCapStyle = .round
        NSColor.black.setStroke()
        stemPath.stroke()

        image.unlockFocus()
        image.isTemplate = true
        return image
    }
}
