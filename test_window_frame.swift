import AppKit

let app = NSApplication.shared
let screen = NSScreen.main!
print("screen.frame: \(screen.frame)")

let win1 = NSWindow(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false, screen: screen)
print("win1 (using screen.frame): \(win1.frame)")

let win2 = NSWindow(contentRect: NSRect(origin: .zero, size: screen.frame.size), styleMask: .borderless, backing: .buffered, defer: false, screen: screen)
print("win2 (using .zero origin): \(win2.frame)")

