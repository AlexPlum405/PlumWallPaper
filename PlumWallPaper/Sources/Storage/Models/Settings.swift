//
//  Settings.swift
//  PlumWallPaper
//
//  Created on 2026-04-28.
//

import Foundation
import SwiftData
import CoreGraphics

/// 应用设置数据模型
@Model
final class Settings {
    // MARK: - Slideshow
    /// 启用自动轮播
    var slideshowEnabled: Bool

    /// 轮播间隔（秒）
    var slideshowInterval: TimeInterval

    /// 轮播顺序
    var slideshowOrder: SlideshowOrder

    /// 过渡效果
    var transitionEffect: TransitionEffect

    // MARK: - Performance
    /// 启用垂直同步
    var vSyncEnabled: Bool

    /// 启用预解码
    var preDecodeEnabled: Bool

    /// 启用音频避让
    var audioDuckingEnabled: Bool

    // MARK: - Power Management
    /// 电池供电时暂停
    var pauseOnBattery: Bool

    /// 全屏应用时暂停
    var pauseOnFullscreen: Bool

    /// 遮挡感知（窗口遮挡时暂停）
    var pauseOnOcclusion: Bool

    /// 低电量时暂停
    var pauseOnLowBattery: Bool

    /// 屏幕共享时暂停
    var pauseOnScreenSharing: Bool

    /// 合盖模式（笔记本合盖时暂停）
    var pauseOnLidClosed: Bool

    /// 高负载避让（CPU > 80% 时暂停）
    var pauseOnHighLoad: Bool

    /// 应用失去焦点时暂停
    var pauseOnLostFocus: Bool

    /// 睡眠预停（进入睡眠前停止）
    var pauseBeforeSleep: Bool

    // MARK: - Display
    /// 显示拓扑模式
    var displayTopology: DisplayTopology

    /// 色彩空间
    var colorSpace: ColorSpace

    // MARK: - Library
    /// 资源库路径
    var libraryPath: String

    /// 缓存阈值（字节）
    var cacheThreshold: Int64

    /// 启用自动清理
    var autoCleanEnabled: Bool

    // MARK: - Appearance
    /// 主题模式
    var themeMode: ThemeMode

    /// Accent 颜色（HEX）
    var accentColor: String

    /// 缩略图大小
    var thumbnailSize: ThumbnailSize

    /// 启用动画
    var animationsEnabled: Bool

    /// 开机启动
    var launchAtLogin: Bool?

    /// 菜单栏图标
    var menuBarEnabled: Bool?

    // MARK: - Audio
    /// 全局壁纸音量 (0-100)
    var globalVolume: Int?

    /// 默认静音启动
    var defaultMuted: Bool?

    /// 仅预览时允许声音
    var previewOnlyAudio: Bool?

    /// 显示器物理排列顺序（screen ID 数组）
    var screenOrder: [String]?

    init(
        slideshowEnabled: Bool = false,
        slideshowInterval: TimeInterval = 1800, // 30 分钟
        slideshowOrder: SlideshowOrder = .sequential,
        transitionEffect: TransitionEffect = .fade,
        vSyncEnabled: Bool = true,
        preDecodeEnabled: Bool = true,
        audioDuckingEnabled: Bool = true,
        pauseOnBattery: Bool = true,
        pauseOnFullscreen: Bool = true,
        pauseOnOcclusion: Bool = false,
        pauseOnLowBattery: Bool = true,
        pauseOnScreenSharing: Bool = false,
        pauseOnLidClosed: Bool = true,
        pauseOnHighLoad: Bool = true,
        pauseOnLostFocus: Bool = false,
        pauseBeforeSleep: Bool = true,
        displayTopology: DisplayTopology = .independent,
        colorSpace: ColorSpace = .p3,
        libraryPath: String = NSHomeDirectory() + "/Pictures/PlumWallPaper",
        cacheThreshold: Int64 = 2_000_000_000, // 2GB
        autoCleanEnabled: Bool = true,
        themeMode: ThemeMode = .auto,
        accentColor: String = "#E03E3E",
        thumbnailSize: ThumbnailSize = .medium,
        animationsEnabled: Bool = true
    ) {
        self.slideshowEnabled = slideshowEnabled
        self.slideshowInterval = slideshowInterval
        self.slideshowOrder = slideshowOrder
        self.transitionEffect = transitionEffect
        self.vSyncEnabled = vSyncEnabled
        self.preDecodeEnabled = preDecodeEnabled
        self.audioDuckingEnabled = audioDuckingEnabled
        self.pauseOnBattery = pauseOnBattery
        self.pauseOnFullscreen = pauseOnFullscreen
        self.pauseOnOcclusion = pauseOnOcclusion
        self.pauseOnLowBattery = pauseOnLowBattery
        self.pauseOnScreenSharing = pauseOnScreenSharing
        self.pauseOnLidClosed = pauseOnLidClosed
        self.pauseOnHighLoad = pauseOnHighLoad
        self.pauseOnLostFocus = pauseOnLostFocus
        self.pauseBeforeSleep = pauseBeforeSleep
        self.displayTopology = displayTopology
        self.colorSpace = colorSpace
        self.libraryPath = libraryPath
        self.cacheThreshold = cacheThreshold
        self.autoCleanEnabled = autoCleanEnabled
        self.themeMode = themeMode
        self.accentColor = accentColor
        self.thumbnailSize = thumbnailSize
        self.animationsEnabled = animationsEnabled
    }
}

// MARK: - Enums

enum SlideshowOrder: String, Codable {
    case sequential = "sequential"
    case random = "random"
    case favoritesFirst = "favoritesFirst"

    var displayName: String {
        switch self {
        case .sequential: return "顺序"
        case .random: return "随机"
        case .favoritesFirst: return "收藏优先"
        }
    }
}

enum TransitionEffect: String, Codable {
    case fade = "fade"
    case kenBurns = "kenBurns"
    case none = "none"

    var displayName: String {
        switch self {
        case .fade: return "淡入淡出"
        case .kenBurns: return "Ken Burns"
        case .none: return "无"
        }
    }
}

enum DisplayTopology: String, Codable {
    case independent = "independent"
    case mirror = "mirror"
    case mirrored = "mirrored"
    case panorama = "panorama"

    var displayName: String {
        switch self {
        case .independent: return "独立显示"
        case .mirror, .mirrored: return "镜像"
        case .panorama: return "全景拼接"
        }
    }
}

enum ColorSpace: String, Codable {
    case p3 = "p3"
    case srgb = "srgb"
    case adobeRGB = "adobeRGB"

    var displayName: String {
        switch self {
        case .p3: return "Display P3"
        case .srgb: return "sRGB"
        case .adobeRGB: return "Adobe RGB"
        }
    }

    var cgColorSpace: CGColorSpace {
        switch self {
        case .p3: return CGColorSpace(name: CGColorSpace.displayP3) ?? CGColorSpace(name: CGColorSpace.sRGB)!
        case .srgb: return CGColorSpace(name: CGColorSpace.sRGB)!
        case .adobeRGB: return CGColorSpace(name: CGColorSpace.adobeRGB1998) ?? CGColorSpace(name: CGColorSpace.sRGB)!
        }
    }
}

enum ThemeMode: String, Codable {
    case auto = "auto"
    case system = "system"
    case light = "light"
    case dark = "dark"

    var displayName: String {
        switch self {
        case .auto, .system: return "自动"
        case .light: return "浅色"
        case .dark: return "深色"
        }
    }
}

enum ThumbnailSize: String, Codable {
    case small = "small"
    case medium = "medium"
    case large = "large"

    var displayName: String {
        switch self {
        case .small: return "小"
        case .medium: return "中"
        case .large: return "大"
        }
    }

    var pixelSize: CGSize {
        switch self {
        case .small: return CGSize(width: 200, height: 112)
        case .medium: return CGSize(width: 300, height: 169)
        case .large: return CGSize(width: 400, height: 225)
        }
    }
}
