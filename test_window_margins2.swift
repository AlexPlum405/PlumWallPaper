import AppKit

let app = NSApplication.shared
let screen = NSScreen.main!

class TestWindow: NSWindow {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

let win1 = TestWindow(
    contentRect: screen.frame,
    styleMask: .borderless,
    backing: .buffered,
    defer: false
)
win1.setFrame(screen.frame, display: true)
win1.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)))
win1.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
win1.isOpaque = true
win1.backgroundColor = .red
win1.hasShadow = false
win1.ignoresMouseEvents = true

let view = NSView(frame: win1.contentView!.bounds)
view.wantsLayer = true
view.layer?.backgroundColor = NSColor.red.cgColor
win1.contentView = view

win1.orderBack(nil)

// Run for 4 seconds
DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
    NSApplication.shared.terminate(nil)
}

app.run()
