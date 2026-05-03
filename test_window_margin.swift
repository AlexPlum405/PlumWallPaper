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
win1.level = NSWindow.Level(rawValue: -1)
win1.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
win1.backgroundColor = .red

print("win1 (level -1) frame: \(win1.frame)")

let win2 = TestWindow(
    contentRect: screen.frame,
    styleMask: .borderless,
    backing: .buffered,
    defer: false
)
win2.setFrame(screen.frame, display: true)
win2.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)))
win2.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
win2.backgroundColor = .blue

print("win2 (desktopWindow) frame: \(win2.frame)")

