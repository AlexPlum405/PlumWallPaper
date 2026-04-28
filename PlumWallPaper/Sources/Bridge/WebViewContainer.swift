//
//  WebViewContainer.swift
//  PlumWallPaper
//
//  Created on 2026-04-28.
//

import SwiftUI
import WebKit
import SwiftData

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

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground")

        // 创建 WebBridge 并保存到 Coordinator 以防止被释放
        let bridge = WebBridge(modelContext: modelContext, webView: webView)
        context.coordinator.bridge = bridge
        contentController.add(bridge, name: "bridge")

        // 保存 webView 引用到 AppViewModel
        viewModel.webView = webView

        // 加载本地 HTML 文件
        if let htmlURL = Bundle.main.url(
            forResource: "plumwallpaper",
            withExtension: "html",
            subdirectory: "Resources/Web"
        ) {
            webView.loadFileURL(htmlURL, allowingReadAccessTo: URL(fileURLWithPath: NSHomeDirectory()))
        }

        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        // No-op
    }

    // MARK: - Coordinator

    @MainActor
    final class Coordinator {
        var bridge: WebBridge?
    }
}
