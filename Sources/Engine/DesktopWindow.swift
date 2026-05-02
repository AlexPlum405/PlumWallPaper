// Sources/Engine/DesktopWindow.swift
import AppKit
import AVFoundation

final class DesktopWindow: NSWindow {
    private(set) var playerLayer: AVPlayerLayer!
    let player: AVPlayer

    init(screen: NSScreen) {
        self.player = AVPlayer()
        self.playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill

        super.init(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        self.setFrame(screen.frame, display: true)

        // 设置为真正的桌面级窗口，防止 macOS Sonoma 缩放
        self.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)))
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        self.isOpaque = true
        self.hasShadow = false
        self.ignoresMouseEvents = true
        self.isMovable = false
        self.backgroundColor = .black
        self.isReleasedWhenClosed = false

        let screenBounds = NSRect(origin: .zero, size: screen.frame.size)
        let scale = screen.backingScaleFactor
        let view = NSView(frame: screenBounds)
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.clear.cgColor
        view.layer?.masksToBounds = true
        view.layer?.contentsScale = scale
        playerLayer.frame = screenBounds
        playerLayer.contentsScale = scale
        playerLayer.contentsGravity = .resizeAspectFill
        playerLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        view.layer?.addSublayer(playerLayer)
        self.contentView = view

        NSLog("[DesktopWindow] init screen=\(screen.localizedName) frame=\(screen.frame) scale=\(scale) level=\(self.level.rawValue)")
    }

    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        self.player = AVPlayer()
        self.playerLayer = AVPlayerLayer(player: player)
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
        commonInit()
    }

    private func commonInit() {
        self.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)))
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        self.isOpaque = true
        self.hasShadow = false
        self.ignoresMouseEvents = true
        self.isMovable = false
        self.backgroundColor = .black
        self.isReleasedWhenClosed = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    func show() {
        orderBack(nil)
        if let contentView = self.contentView {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            playerLayer.frame = contentView.bounds
            if let window = contentView.window {
                let scale = window.backingScaleFactor
                contentView.layer?.contentsScale = scale
                playerLayer.contentsScale = scale
            }
            CATransaction.commit()
        }
    }

    func hide() {
        orderOut(nil)
    }
}
