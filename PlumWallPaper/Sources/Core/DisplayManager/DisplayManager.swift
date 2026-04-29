import Foundation
import AppKit
import Observation

/// 显示器管理器
@Observable
final class DisplayManager {
    static let shared = DisplayManager()

    private(set) var availableScreens: [ScreenInfo] = []

    private init() {
        refreshScreens()
        startMonitoring()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    /// 刷新当前可用显示器列表
    func refreshScreens() {
        availableScreens = NSScreen.screens.enumerated().map { index, screen in
            let description = screen.deviceDescription
            let screenNumber = description[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber
            let screenID = screenNumber?.stringValue ?? "screen-\(index)"
            let displayID = screenNumber?.uint32Value ?? 0
            let frame = screen.frame
            let resolution = "\(Int(frame.width))×\(Int(frame.height))"
            let isBuiltIn = CGDisplayIsBuiltin(displayID) != 0
            let name = screen.localizedName
            return ScreenInfo(id: screenID, name: name, resolution: resolution, isMain: isBuiltIn)
        }
    }

    /// 根据 ScreenInfo 查找 NSScreen
    func screen(for screenInfo: ScreenInfo) -> NSScreen? {
        NSScreen.screens.first { screen in
            let description = screen.deviceDescription
            let screenNumber = description[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber
            return screenNumber?.stringValue == screenInfo.id
        }
    }

    /// 获取所有显示器的刷新率
    func getRefreshRates() -> [String: Int] {
        var rates: [String: Int] = [:]
        for (index, screen) in NSScreen.screens.enumerated() {
            let description = screen.deviceDescription
            let screenNumber = description[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber
            let screenID = screenNumber?.stringValue ?? "screen-\(index)"
            rates[screenID] = screen.maximumFramesPerSecond
        }
        return rates
    }

    /// 获取所有显示器中的最大刷新率
    func getMaxRefreshRate() -> Int {
        return NSScreen.screens.map { $0.maximumFramesPerSecond }.max() ?? 60
    }

    private func startMonitoring() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleScreensChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    @objc private func handleScreensChanged() {
        refreshScreens()
    }
}
