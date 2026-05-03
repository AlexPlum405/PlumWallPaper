import AppKit

let screen = NSScreen.screens.last! // If there's a second screen, test there. Otherwise main.
print("Screen frame: \(screen.frame)")

let win1 = NSWindow(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false, screen: screen)
print("win1 (using screen.frame with screen parameter) frame: \(win1.frame)")

let win2 = NSWindow(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false)
win2.setFrame(screen.frame, display: true)
print("win2 (using setFrame) frame: \(win2.frame)")

