import AppKit

let app = NSApplication.shared
let screen = NSScreen.main!

print("Screen frame: \(screen.frame)")
print("Screen visibleFrame: \(screen.visibleFrame)")

let win = NSWindow(
    contentRect: screen.frame,
    styleMask: .borderless,
    backing: .buffered,
    defer: false,
    screen: screen
)

print("Window frame after init: \(win.frame)")

let screenBounds = NSRect(origin: .zero, size: screen.frame.size)
let view = NSView(frame: screenBounds)
win.contentView = view

print("ContentView bounds: \(view.bounds)")
print("ContentView frame: \(view.frame)")
print("Window frame after setting contentView: \(win.frame)")

