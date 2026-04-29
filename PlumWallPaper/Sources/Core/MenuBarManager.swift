import AppKit

@MainActor
final class MenuBarManager {
    static let shared = MenuBarManager()

    private var statusItem: NSStatusItem?
    private weak var window: NSWindow?
    private var appearanceObservation: NSKeyValueObservation?

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
            updateIcon(for: item)

            // 监听菜单栏外观变化，自动切换图标
            appearanceObservation = item.button?.observe(\.effectiveAppearance, options: [.new]) { [weak self] button, _ in
                Task { @MainActor in
                    guard let self, let item = self.statusItem else { return }
                    self.updateIcon(for: item)
                }
            }

            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "打开 PlumWallPaper", action: #selector(openMainWindow), keyEquivalent: ""))
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "退出", action: #selector(quitApp), keyEquivalent: "q"))
            menu.items.forEach { $0.target = self }
            item.menu = menu
            statusItem = item
        } else {
            appearanceObservation?.invalidate()
            appearanceObservation = nil
            if let item = statusItem {
                NSStatusBar.system.removeStatusItem(item)
                statusItem = nil
            }
        }
    }

    private func updateIcon(for item: NSStatusItem) {
        let isDark = item.button?.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        item.button?.image = Self.makeIcon(darkMenuBar: isDark)
    }

    @objc private func openMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    private static func makeIcon(darkMenuBar: Bool) -> NSImage {
        let bodyColor: NSColor = darkMenuBar ? .white : .black
        let stemColor: NSColor = darkMenuBar ? NSColor(white: 0.55, alpha: 1.0) : NSColor(white: 0.45, alpha: 1.0)

        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size)
        image.lockFocus()

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
        bodyColor.setFill()
        plumPath.fill()

        let stemPath = NSBezierPath()
        stemPath.move(to: NSPoint(x: 9.0, y: 14.4))
        stemPath.line(to: NSPoint(x: 9.0, y: 17.1))
        stemPath.lineWidth = 1.8
        stemPath.lineCapStyle = .round
        stemColor.setStroke()
        stemPath.stroke()

        image.unlockFocus()
        image.isTemplate = false
        return image
    }
}
