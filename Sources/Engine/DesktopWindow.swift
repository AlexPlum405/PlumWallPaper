// Sources/Engine/DesktopWindow.swift
import AppKit
import MetalKit

final class DesktopWindow: NSWindow {
    let mtkView: MTKView

    init(screen: NSScreen, device: MTLDevice) {
        let mtkView = MTKView(frame: screen.frame, device: device)
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.framebufferOnly = false
        mtkView.isPaused = true
        mtkView.enableSetNeedsDisplay = false
        self.mtkView = mtkView

        super.init(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false,
            screen: screen
        )

        self.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)) - 1)
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        self.isOpaque = true
        self.hasShadow = false
        self.ignoresMouseEvents = true
        self.backgroundColor = .black
        self.contentView = mtkView
    }

    func show() {
        orderFrontRegardless()
    }

    func hide() {
        orderOut(nil)
    }
}
