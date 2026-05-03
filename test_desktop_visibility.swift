import AppKit

let app = NSApplication.shared
let screen = NSScreen.main!

let win = NSWindow(
    contentRect: screen.frame,
    styleMask: .borderless,
    backing: .buffered,
    defer: false
)
win.setFrame(screen.frame, display: true)
win.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)))
win.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
win.isOpaque = true
win.backgroundColor = .green

let view = NSView(frame: win.contentView!.bounds)
view.wantsLayer = true
view.layer?.backgroundColor = NSColor.red.cgColor
win.contentView = view

win.makeKeyAndOrderFront(nil)

// Run for 3 seconds
DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
    NSApplication.shared.terminate(nil)
}

app.run()
