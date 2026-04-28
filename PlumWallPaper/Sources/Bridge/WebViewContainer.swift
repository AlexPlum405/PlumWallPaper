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

/// NSViewRepresentable 包装 WKWebView，加载本地 HTML 并注入 WebBridge
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
        webView.layerContentsRedrawPolicy = .onSetNeedsDisplay
        webView.layer?.isOpaque = true
        webView.isInspectable = true
        webView.navigationDelegate = context.coordinator
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
        contentController.add(bridge, name: "bridge")

        // 捕获 console.log/error
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
        // No-op
    }

    // MARK: - Coordinator

    @MainActor
    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var bridge: WebBridge?

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

// MARK: - 支持拖拽文件的 WKWebView 子类

@MainActor
final class DropEnabledWebView: WKWebView {
    var onDropFiles: (([URL]) -> Void)?

    private static let supportedExtensions: Set<String> = ["mp4", "mov", "m4v", "heic", "heif"]
    private var resizeSnapshotView: NSView?

    override var preservesContentDuringLiveResize: Bool {
        true
    }

    override func viewWillStartLiveResize() {
        super.viewWillStartLiveResize()
        guard resizeSnapshotView == nil else { return }
        guard let rep = bitmapImageRepForCachingDisplay(in: bounds) else { return }
        cacheDisplay(in: bounds, to: rep)
        let image = NSImage(size: bounds.size)
        image.addRepresentation(rep)
        let imageView = NSImageView(frame: bounds)
        imageView.image = image
        imageView.imageScaling = .scaleAxesIndependently
        imageView.autoresizingMask = [.width, .height]
        imageView.wantsLayer = true
        imageView.layer?.backgroundColor = NSColor(red: 0.05, green: 0.055, blue: 0.07, alpha: 1.0).cgColor
        addSubview(imageView)
        resizeSnapshotView = imageView
        layer?.opacity = 0
    }

    override func viewDidEndLiveResize() {
        super.viewDidEndLiveResize()
        guard let snapshot = resizeSnapshotView else { return }
        layer?.opacity = 1
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            snapshot.animator().alphaValue = 0
        }, completionHandler: {
            snapshot.removeFromSuperview()
        })
        resizeSnapshotView = nil
        needsDisplay = true
    }

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
