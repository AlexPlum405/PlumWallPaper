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

    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        // 创建一个默认的 MTKView（如果通过这个初始化器调用）
        self.mtkView = MTKView(frame: contentRect, device: MTLCreateSystemDefaultDevice())
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show() {
        orderFrontRegardless()
    }

    func hide() {
        orderOut(nil)
    }
}

