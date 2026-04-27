//
//  DesktopBridge.swift
//  PlumWallPaper
//
//  Created on 2026-04-28.
//

import Foundation
import AppKit

/// macOS 桌面壁纸 API 封装
final class DesktopBridge {
    /// 设置 HEIC 动态壁纸
    @MainActor
    func setDesktopImage(_ url: URL, for screen: NSScreen) throws {
        try NSWorkspace.shared.setDesktopImageURL(url, for: screen)
    }

    /// 获取所有显示器
    var screens: [NSScreen] {
        NSScreen.screens
    }

    /// 获取主显示器
    var mainScreen: NSScreen? {
        NSScreen.main
    }
}
