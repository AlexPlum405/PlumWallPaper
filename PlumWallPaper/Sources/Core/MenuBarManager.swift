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

        // 李子主体：SVG path 缩放 0.45 + Y 轴翻转（SVG Y↓, NSBezierPath Y↑）
        // 原始 SVG: M20 36C28 36 34 30 34 22C34 14 20 6 20 6C20 6 6 14 6 22C6 30 12 36 20 36Z
        let plumPath = NSBezierPath()
        plumPath.move(to: NSPoint(x: 9.0, y: 1.8))
        plumPath.curve(to: NSPoint(x: 15.3, y: 8.1),
                       controlPoint1: NSPoint(x: 12.6, y: 1.8),
                       controlPoint2: NSPoint(x: 15.3, y: 4.5))
        plumPath.curve(to: NSPoint(x: 9.0, y: 15.3),
                       controlPoint1: NSPoint(x: 15.3, y: 11.7),
                       controlPoint2: NSPoint(x: 9.0, y: 15.3))
        plumPath.curve(to: NSPoint(x: 2.7, y: 8.1),
                       controlPoint1: NSPoint(x: 9.0, y: 15.3),
                       controlPoint2: NSPoint(x: 2.7, y: 11.7))
        plumPath.curve(to: NSPoint(x: 9.0, y: 1.8),
                       controlPoint1: NSPoint(x: 2.7, y: 4.5),
                       controlPoint2: NSPoint(x: 5.4, y: 1.8))
        plumPath.close()
        NSColor.black.setFill()
        plumPath.fill()

        // 茎：从李子顶部向上延伸，用灰色实现 template 模式下的双色效果
        let stemPath = NSBezierPath()
        stemPath.move(to: NSPoint(x: 9.0, y: 14.4))
        stemPath.line(to: NSPoint(x: 9.0, y: 17.1))
        stemPath.lineWidth = 1.35
        stemPath.lineCapStyle = .round
        NSColor(white: 0.45, alpha: 1.0).setStroke()
        stemPath.stroke()

        image.unlockFocus()
        image.isTemplate = true
        return image
    }
}
