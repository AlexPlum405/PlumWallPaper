import Foundation
import AppKit
import IOKit.ps

@MainActor
final class PauseStrategyManager {
    static let shared = PauseStrategyManager()

    private var isMonitoring = false
    private var pollTimer: Timer?
    private var temporarilyResumed = false
    private var manuallyPaused = false

    private(set) var pauseReason: String? = nil

    private init() {}

    func startMonitoring(settingsProvider: @escaping () -> [String: Any]) {
        guard !isMonitoring else { return }
        isMonitoring = true
        self.settingsProvider = settingsProvider

        NotificationCenter.default.addObserver(self, selector: #selector(handleSleepNotification),
            name: NSWorkspace.willSleepNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleWakeNotification),
            name: NSWorkspace.didWakeNotification, object: nil)

        // 事件驱动：应用切换时立即检测
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(handleAppChange),
            name: NSWorkspace.didActivateApplicationNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(handleAppChange),
            name: NSWorkspace.didDeactivateApplicationNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(handleAppChange),
            name: NSWorkspace.didLaunchApplicationNotification, object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(handleAppChange),
            name: NSWorkspace.didTerminateApplicationNotification, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(handleScreenChange),
            name: NSApplication.didChangeScreenParametersNotification, object: nil)

        // 兜底轮询（处理电池状态等无事件通知的场景）
        pollTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.evaluatePauseConditions() }
        }

        // 启动监控后立即评估一次，确保初始状态正确
        evaluatePauseConditions()
    }

    /// 临时恢复（直到下次触发条件变化）
    func resumeTemporarily() {
        temporarilyResumed = true
        pauseReason = nil
        WallpaperEngine.shared.resumeAll()
    }

    /// 设置变更后立即重新评估暂停条件
    func reevaluate() {
        temporarilyResumed = false
        evaluatePauseConditions()
    }

    private var settingsProvider: (() -> [String: Any])?

    private func getSettings() -> [String: Any] {
        settingsProvider?() ?? [:]
    }

    @objc private func handleAppChange(_ notification: Notification) {
        temporarilyResumed = false
        evaluatePauseConditions()
    }

    @objc private func handleScreenChange() {
        evaluatePauseConditions()
    }

    private func evaluatePauseConditions() {
        if manuallyPaused {
            pauseReason = "手动暂停"
            WallpaperEngine.shared.pauseAll()
            return
        }

        let s = getSettings()
        var reasons: [String] = []

        if s["pauseOnBattery"] as? Bool == true && isOnBattery() {
            reasons.append("电池供电模式")
        }
        if s["pauseOnFullscreen"] as? Bool == true && hasFullscreenApp() {
            reasons.append("全屏应用运行中")
        }
        if s["pauseOnLowBattery"] as? Bool == true && ProcessInfo.processInfo.isLowPowerModeEnabled {
            reasons.append("低电量模式")
        }
        if s["pauseOnScreenSharing"] as? Bool == true && isScreenSharing() {
            reasons.append("屏幕共享/录制中")
        }
        if s["pauseOnHighLoad"] as? Bool == true && isHighLoadAppRunning(s) {
            reasons.append("高负载应用运行中")
        }
        if s["pauseOnLostFocus"] as? Bool == true && !isDesktopFocused() {
            reasons.append("桌面未处于前台")
        }

        if !reasons.isEmpty && !temporarilyResumed {
            pauseReason = reasons.joined(separator: " · ")
            WallpaperEngine.shared.pauseAll()
        } else {
            pauseReason = nil
            WallpaperEngine.shared.resumeAll()
        }
    }

    @objc private func handleSleepNotification() {
        let s = getSettings()
        if s["pauseBeforeSleep"] as? Bool == true {
            pauseReason = "系统即将进入睡眠"
            WallpaperEngine.shared.pauseAll()
        }
    }

    @objc private func handleWakeNotification() {
        temporarilyResumed = false
        manuallyPaused = false
        evaluatePauseConditions()
    }

    /// 手动暂停/恢复切换（快捷键用）
    func toggleManualPause() {
        if manuallyPaused {
            manuallyPaused = false
            evaluatePauseConditions()
        } else {
            manuallyPaused = true
            temporarilyResumed = false
            pauseReason = "手动暂停"
            WallpaperEngine.shared.pauseAll()
        }
    }

    // MARK: - Detection Methods

    private func isOnBattery() -> Bool {
        let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue()
        guard let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef] else { return false }
        for source in sources {
            if let info = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any],
               let type = info[kIOPSPowerSourceStateKey] as? String {
                return type == kIOPSBatteryPowerValue
            }
        }
        return false
    }

    private func hasFullscreenApp() -> Bool {
        guard let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else {
            return false
        }

        let screenSizes = NSScreen.screens.map { $0.frame.size }

        for window in windowList {
            if let ownerName = window[kCGWindowOwnerName as String] as? String,
               ownerName == "PlumWallPaper" {
                continue
            }

            guard let layer = window[kCGWindowLayer as String] as? Int, layer == 0 else { continue }

            if let boundsDict = window[kCGWindowBounds as String] as? [String: Any],
               let width = boundsDict["Width"] as? CGFloat,
               let height = boundsDict["Height"] as? CGFloat {
                for screenSize in screenSizes {
                    if abs(width - screenSize.width) < 10 && abs(height - screenSize.height) < 10 {
                        return true
                    }
                }
            }
        }
        return false
    }

    /// 桌面是否处于前台：前台应用为 Finder 或无前台应用（显示桌面）
    private func isDesktopFocused() -> Bool {
        guard let frontmost = NSWorkspace.shared.frontmostApplication else { return true }
        let bundleId = frontmost.bundleIdentifier
        return bundleId == "com.apple.finder" || bundleId == Bundle.main.bundleIdentifier
    }

    private func isScreenSharing() -> Bool {
        let screenRecordingApps = [
            "com.apple.QuickTimePlayerX",
            "com.obsproject.obs-studio",
            "com.telestream.screenflow9",
            "com.telestream.screenflow10",
            "com.techsmith.camtasia2021",
            "us.zoom.xos",
            "com.microsoft.teams",
            "com.microsoft.teams2",
            "com.tencent.meeting",
            "com.cisco.webexmeetings",
            "com.skype.skype",
            "com.loom.desktop"
        ]

        let running = NSWorkspace.shared.runningApplications
        return running.contains { app in
            guard let bundleId = app.bundleIdentifier else { return false }
            return screenRecordingApps.contains(bundleId)
        }
    }

    private func isHighLoadAppRunning(_ s: [String: Any]) -> Bool {
        // 检查应用规则黑名单
        if let rules = s["appRules"] as? [[String: Any]] {
            let running = NSWorkspace.shared.runningApplications
            for rule in rules {
                guard let bundleId = rule["bundleIdentifier"] as? String,
                      let action = rule["action"] as? String,
                      action == "pause" else { continue }
                if running.contains(where: { $0.bundleIdentifier == bundleId }) {
                    return true
                }
            }
        }

        // 兜底：CPU > 80%
        return cpuUsage() > 80
    }

    private func cpuUsage() -> Double {
        var cpuInfo: processor_info_array_t?
        var numCpuInfo: mach_msg_type_number_t = 0
        var numCpus: natural_t = 0

        let result = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &numCpus, &cpuInfo, &numCpuInfo)
        guard result == KERN_SUCCESS, let cpuInfo else { return 0 }

        let cpuLoad = cpuInfo.withMemoryRebound(to: integer_t.self, capacity: Int(numCpuInfo)) { ptr in
            var totalUser: UInt32 = 0
            var totalSystem: UInt32 = 0
            var totalIdle: UInt32 = 0
            for i in stride(from: 0, to: Int(numCpuInfo), by: Int(CPU_STATE_MAX)) {
                totalUser += UInt32(ptr[i + Int(CPU_STATE_USER)])
                totalSystem += UInt32(ptr[i + Int(CPU_STATE_SYSTEM)])
                totalIdle += UInt32(ptr[i + Int(CPU_STATE_IDLE)])
            }
            let total = totalUser + totalSystem + totalIdle
            return total > 0 ? Double(totalUser + totalSystem) / Double(total) * 100 : 0
        }

        vm_deallocate(mach_task_self_, vm_address_t(bitPattern: cpuInfo), vm_size_t(numCpuInfo) * vm_size_t(MemoryLayout<integer_t>.size))
        return cpuLoad
    }
}
