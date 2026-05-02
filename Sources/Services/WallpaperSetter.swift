// Sources/Services/WallpaperSetter.swift
import Foundation
import AppKit

/// 壁纸设置服务
@MainActor
class WallpaperSetter {
    static let shared = WallpaperSetter()

    private init() {}

    /// 设置壁纸到所有屏幕
    func setWallpaper(imageURL: URL) throws {
        NSLog("[WallpaperSetter] 开始设置壁纸: \(imageURL.lastPathComponent)")

        guard FileManager.default.fileExists(atPath: imageURL.path) else {
            NSLog("[WallpaperSetter] ❌ 文件不存在: \(imageURL.path)")
            throw WallpaperSetterError.fileNotFound
        }

        var errors: [Error] = []

        for screen in NSScreen.screens {
            do {
                try NSWorkspace.shared.setDesktopImageURL(imageURL, for: screen)
                NSLog("[WallpaperSetter] ✅ 设置成功: Screen \(screen.localizedName)")
            } catch {
                NSLog("[WallpaperSetter] ❌ 设置失败: \(error.localizedDescription)")
                errors.append(error)
            }
        }

        if !errors.isEmpty {
            throw WallpaperSetterError.partialFailure(errors)
        }

        NSLog("[WallpaperSetter] ✅ 所有屏幕设置完成")
    }

    /// 设置壁纸到指定屏幕
    func setWallpaper(imageURL: URL, for screen: NSScreen) throws {
        NSLog("[WallpaperSetter] 设置壁纸到屏幕: \(screen.localizedName)")

        guard FileManager.default.fileExists(atPath: imageURL.path) else {
            throw WallpaperSetterError.fileNotFound
        }

        try NSWorkspace.shared.setDesktopImageURL(imageURL, for: screen)
        NSLog("[WallpaperSetter] ✅ 设置成功")
    }
}

enum WallpaperSetterError: LocalizedError {
    case fileNotFound
    case partialFailure([Error])

    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "壁纸文件不存在"
        case .partialFailure(let errors):
            return "部分屏幕设置失败: \(errors.count) 个错误"
        }
    }
}
