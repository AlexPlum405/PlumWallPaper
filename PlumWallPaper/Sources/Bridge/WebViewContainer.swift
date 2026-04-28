//
//  WebViewContainer.swift
//  PlumWallPaper
//
//  Created on 2026-04-28.
//

import SwiftUI
import WebKit
import SwiftData
import AppKit
import UniformTypeIdentifiers

struct WebViewContainer: NSViewRepresentable {
    let viewModel: AppViewModel
    let modelContext: ModelContext

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let contentController = WKUserContentController()
        config.userContentController = contentController
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")

        let webView = DropEnabledWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground")
        webView.wantsLayer = true
        webView.layer?.isOpaque = true
        webView.isInspectable = true
        webView.navigationDelegate = context.coordinator
        webView.windowCoordinator = context.coordinator
        webView.registerForDraggedTypes([.fileURL])
        webView.onDropFiles = { urls in
            Task { @MainActor in
                do {
                    let imported = try await FileImporter.shared.importFiles(urls: urls)
                    let store = WallpaperStore(modelContext: modelContext)
                    try store.addWallpapers(imported)
                    webView.evaluateJavaScript("window.location.reload()") { _, _ in }
                } catch {
                    NSLog("[WebView] Drop import failed: %@", error.localizedDescription)
                }
            }
        }

        let bridge = WebBridge(modelContext: modelContext, webView: webView)
        context.coordinator.bridge = bridge
        context.coordinator.setWebView(webView)
        contentController.add(bridge, name: "bridge")

        let consoleScript = """
        (function() {
            const originalLog = console.log;
            const originalError = console.error;
            console.log = function(...args) {
                originalLog.apply(console, args);
                window.webkit.messageHandlers.consoleLog.postMessage(args.join(' '));
            };
            console.error = function(...args) {
                originalError.apply(console, args);
                window.webkit.messageHandlers.consoleError.postMessage(args.join(' '));
            };
        })();
        """
        let userScript = WKUserScript(source: consoleScript, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        contentController.addUserScript(userScript)
        contentController.add(context.coordinator, name: "consoleLog")
        contentController.add(context.coordinator, name: "consoleError")

        viewModel.webView = webView

        if let htmlURL = Bundle.main.url(forResource: "plumwallpaper", withExtension: "html") {
            NSLog("[WebView] Loading HTML: %@", htmlURL.absoluteString)
            webView.loadFileURL(htmlURL, allowingReadAccessTo: URL(fileURLWithPath: "/"))
        } else {
            NSLog("[WebView] ERROR: plumwallpaper.html not found in bundle!")
            NSLog("[WebView] Bundle path: %@", Bundle.main.bundlePath)
            if let resourcePath = Bundle.main.resourcePath {
                let files = (try? FileManager.default.contentsOfDirectory(atPath: resourcePath)) ?? []
                NSLog("[WebView] Resources: %@", files.joined(separator: ", "))
            }
        }

        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
    }

    // MARK: - Coordinator

    @MainActor
    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler, NSWindowDelegate {
        var bridge: WebBridge?
        private weak var webView: DropEnabledWebView?

        func setWebView(_ webView: DropEnabledWebView) {
            self.webView = webView
        }

        func configureWindow(_ window: NSWindow) {
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.styleMask.insert(.fullSizeContentView)
            window.styleMask.insert(.resizable)
            window.isMovableByWindowBackground = false
            window.backgroundColor = NSColor(red: 0.051, green: 0.055, blue: 0.071, alpha: 1.0)
            window.isOpaque = true
            window.hasShadow = true
            if #available(macOS 11.0, *) {
                window.titlebarSeparatorStyle = .none
            }
        }

        // MARK: - Resize 动画优化

        func windowWillStartLiveResize(_ notification: Notification) {
            webView?.freezeForResize()
        }

        func windowDidResize(_ notification: Notification) {
            if let window = notification.object as? NSWindow {
                configureWindow(window)
            }
            webView?.updateSnapshotFrame()
        }

        func windowDidEndLiveResize(_ notification: Notification) {
            if let window = notification.object as? NSWindow {
                configureWindow(window)
            }
            webView?.unfreezeAfterResize()
        }

        // MARK: - 全屏动画优化

        func windowWillEnterFullScreen(_ notification: Notification) {
            webView?.freezeForResize()
        }

        func windowDidEnterFullScreen(_ notification: Notification) {
            if let window = notification.object as? NSWindow {
                configureWindow(window)
            }
            webView?.unfreezeAfterResize()
        }

        func windowWillExitFullScreen(_ notification: Notification) {
            webView?.freezeForResize()
        }

        func windowDidExitFullScreen(_ notification: Notification) {
            guard let window = notification.object as? NSWindow else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.configureWindow(window)
                self.webView?.unfreezeAfterResize()
            }
        }

        func windowDidDeminiaturize(_ notification: Notification) {
            guard let window = notification.object as? NSWindow else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.configureWindow(window)
            }
        }

        func windowDidBecomeKey(_ notification: Notification) {
            if let window = notification.object as? NSWindow {
                configureWindow(window)
            }
        }

        func windowDidBecomeMain(_ notification: Notification) {
            if let window = notification.object as? NSWindow {
                configureWindow(window)
            }
        }

        // MARK: - 最大化动画时间归零（消除系统动画期间的鬼影）

        func windowWillUseStandardFrame(_ window: NSWindow, newFrame: NSRect) -> NSRect {
            return newFrame
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            NSLog("[WebView] Navigation finished, URL: %@", webView.url?.absoluteString ?? "nil")
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            NSLog("[WebView] Navigation failed: %@", error.localizedDescription)
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            NSLog("[WebView] Provisional navigation failed: %@", error.localizedDescription)
        }

        nonisolated func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "consoleLog" {
                NSLog("[JS console.log] %@", String(describing: message.body))
            } else if message.name == "consoleError" {
                NSLog("[JS console.error] %@", String(describing: message.body))
            }
        }
    }
}

// MARK: - DropEnabledWebView

@MainActor
final class DropEnabledWebView: WKWebView {
    var onDropFiles: (([URL]) -> Void)?
    weak var windowCoordinator: WebViewContainer.Coordinator?

    private static let supportedExtensions: Set<String> = ["mp4", "mov", "m4v", "heic", "heif"]
    private var dragBar: TitlebarDragView?

    // Freeze 快照状态
    private var isFrozen = false
    private var frozenSize: NSSize = .zero
    private var snapshotImageView: NSImageView?

    // Resize 边缘
    private static let resizeEdgeThickness: CGFloat = 5

    // MARK: - 视图生命周期

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard let window = window else { return }

        if let coordinator = windowCoordinator {
            window.delegate = coordinator
            coordinator.configureWindow(window)
        }

        installDragBar()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.windowCoordinator?.configureWindow(window)
        }
    }

    // MARK: - Resize 边缘

    override func hitTest(_ point: NSPoint) -> NSView? {
        let b = bounds
        let t = Self.resizeEdgeThickness

        if point.x < t || point.x > b.width - t ||
           point.y < t || point.y > b.height - t {
            return nil
        }

        return super.hitTest(point)
    }

    // MARK: - 拖动条

    private func installDragBar() {
        guard dragBar == nil else { return }
        let bar = TitlebarDragView()
        bar.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bar)
        NSLayoutConstraint.activate([
            bar.topAnchor.constraint(equalTo: topAnchor),
            bar.leadingAnchor.constraint(equalTo: leadingAnchor),
            bar.trailingAnchor.constraint(equalTo: trailingAnchor),
            bar.heightAnchor.constraint(equalToConstant: 52)
        ])
        dragBar = bar
    }

    // MARK: - Freeze / Unfreeze

    func freezeForResize() {
        guard !isFrozen else { return }
        isFrozen = true
        frozenSize = bounds.size

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer?.minificationFilter = .trilinear
        layer?.magnificationFilter = .trilinear
        CATransaction.commit()

        let config = WKSnapshotConfiguration()
        config.rect = CGRect(origin: .zero, size: bounds.size)
        takeSnapshot(with: config) { [weak self] image, _ in
            guard let self, self.isFrozen, let image else { return }
            let iv = NSImageView()
            iv.image = image
            iv.imageScaling = .scaleProportionallyUpOrDown
            iv.frame = CGRect(origin: .zero, size: self.frozenSize)
            iv.wantsLayer = true
            iv.layer?.minificationFilter = .trilinear
            iv.layer?.magnificationFilter = .trilinear
            self.addSubview(iv, positioned: .above, relativeTo: nil)
            self.snapshotImageView = iv
        }
    }

    func updateSnapshotFrame() {
        guard isFrozen, frozenSize.width > 0, frozenSize.height > 0 else { return }
        snapshotImageView?.frame = CGRect(origin: .zero, size: frame.size)
    }

    func unfreezeAfterResize() {
        guard isFrozen else { return }
        isFrozen = false

        if let iv = snapshotImageView {
            if bounds.size != frozenSize {
                let scaled = NSImage(size: bounds.size)
                scaled.lockFocus()
                iv.image?.draw(in: NSRect(origin: .zero, size: bounds.size))
                scaled.unlockFocus()
            }
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = 0.15
                ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
                iv.animator().alphaValue = 0
            }, completionHandler: { [weak self] in
                self?.snapshotImageView?.removeFromSuperview()
                self?.snapshotImageView = nil
            })
        }

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer?.minificationFilter = .linear
        layer?.magnificationFilter = .linear
        CATransaction.commit()
    }

    override func viewWillStartLiveResize() {
        super.viewWillStartLiveResize()
        freezeForResize()
    }

    override func viewDidEndLiveResize() {
        super.viewDidEndLiveResize()
        unfreezeAfterResize()
    }

    // MARK: - 文件拖拽

    override func draggingEntered(_ sender: any NSDraggingInfo) -> NSDragOperation {
        guard hasValidFiles(sender) else { return [] }
        return .copy
    }

    override func performDragOperation(_ sender: any NSDraggingInfo) -> Bool {
        guard let urls = fileURLs(from: sender), !urls.isEmpty else { return false }
        onDropFiles?(urls)
        return true
    }

    private func hasValidFiles(_ info: NSDraggingInfo) -> Bool {
        fileURLs(from: info)?.isEmpty == false
    }

    private func fileURLs(from info: NSDraggingInfo) -> [URL]? {
        info.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: [
            .urlReadingFileURLsOnly: true
        ])?.compactMap { ($0 as? URL) }
         .filter { Self.supportedExtensions.contains($0.pathExtension.lowercased()) }
    }
}

// MARK: - TitlebarDragView

@MainActor
final class TitlebarDragView: NSView {
    override var mouseDownCanMoveWindow: Bool { true }

    override func mouseDown(with event: NSEvent) {
        window?.performDrag(with: event)
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        let windowWidth = window?.frame.width ?? 1200

        if point.x < 300 {
            return nil
        }

        if point.x > windowWidth - 200 {
            return nil
        }

        return super.hitTest(point)
    }
}
