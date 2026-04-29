import Foundation
import AppKit
import IOKit.ps

@MainActor
final class PauseStrategyManager {
    static let shared = PauseStrategyManager()

    private var isMonitoring = false
    private var pollTimer: Timer?

    private init() {}

    func startMonitoring(settingsProvider: @escaping () -> [String: Any]) {
        guard !isMonitoring else { return }
        isMonitoring = true

        NotificationCenter.default.addObserver(self, selector: #selector(handleSleepNotification),
            name: NSWorkspace.willSleepNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleWakeNotification),
            name: NSWorkspace.didWakeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppActivation),
            name: NSApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppDeactivation),
            name: NSApplication.didResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleScreenChange),
            name: NSApplication.didChangeScreenParametersNotification, object: nil)

        self.settingsProvider = settingsProvider
        pollTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.evaluatePauseConditions() }
        }
    }

    private var settingsProvider: (() -> [String: Any])?

    private func getSettings() -> [String: Any] {
        settingsProvider?() ?? [:]
    }

    private func evaluatePauseConditions() {
        let s = getSettings()
        var shouldPause = false

        if s["pauseOnBattery"] as? Bool == true && isOnBattery() { shouldPause = true }
        if s["pauseOnFullscreen"] as? Bool == true && hasFullscreenApp() { shouldPause = true }
        if s["pauseOnOcclusion"] as? Bool == true && isDesktopOccluded() { shouldPause = true }
        if s["pauseOnLowBattery"] as? Bool == true && ProcessInfo.processInfo.isLowPowerModeEnabled { shouldPause = true }
        if s["pauseOnScreenSharing"] as? Bool == true && isScreenSharing() { shouldPause = true }
        if s["pauseOnLidClosed"] as? Bool == true && isLidClosed() { shouldPause = true }
        if s["pauseOnHighLoad"] as? Bool == true && cpuUsage() > 80 { shouldPause = true }
        if s["pauseOnLostFocus"] as? Bool == true && !NSApp.isActive { shouldPause = true }

        if shouldPause {
            WallpaperEngine.shared.pauseAll()
        } else {
            WallpaperEngine.shared.resumeAll()
        }
    }

    @objc private func handleSleepNotification() {
        let s = getSettings()
        if s["pauseBeforeSleep"] as? Bool == true {
            WallpaperEngine.shared.pauseAll()
        }
    }

    @objc private func handleWakeNotification() {
        evaluatePauseConditions()
    }

    @objc private func handleAppActivation() {
        evaluatePauseConditions()
    }

    @objc private func handleAppDeactivation() {
        evaluatePauseConditions()
    }

    @objc private func handleScreenChange() {
        evaluatePauseConditions()
    }

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
        for window in NSApp.windows {
            if window.styleMask.contains(.fullScreen) { return true }
        }
        return false
    }

    private func isDesktopOccluded() -> Bool {
        return false
    }

    private func isScreenSharing() -> Bool {
        return false
    }

    private func isLidClosed() -> Bool {
        return false
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
