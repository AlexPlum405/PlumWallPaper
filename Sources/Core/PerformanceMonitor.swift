import Foundation
import AppKit
import IOKit
import Observation

@Observable
@MainActor
final class PerformanceMonitor {
    static let shared = PerformanceMonitor()

    var fpsLimit: Int = 0
    var currentFPS = 0
    var currentGPULoad: Double = 0
    var currentMemoryMB: Int = 0

    private var pollTimer: Timer?

    private init() {}

    func startMonitoring() {
        guard pollTimer == nil else { return }
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.sample() }
        }
        sample()
    }

    func stopMonitoring() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    private func sample() {
        currentFPS = 60
        currentGPULoad = readGPUUtilization()
        currentMemoryMB = getMemoryUsage()
    }

    func getCurrentMetrics() -> [String: Any] {
        return [
            "gpuLoad": currentGPULoad,
            "fps": currentFPS,
            "memoryMB": currentMemoryMB
        ]
    }

    private func readGPUUtilization() -> Double {
        var iterator: io_iterator_t = 0
        let matching = IOServiceMatching("IOAccelerator")

        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS else {
            return estimateGPUFromFPS()
        }

        defer { IOObjectRelease(iterator) }

        var service = IOIteratorNext(iterator)
        while service != 0 {
            defer {
                IOObjectRelease(service)
                service = IOIteratorNext(iterator)
            }

            var properties: Unmanaged<CFMutableDictionary>?
            guard IORegistryEntryCreateCFProperties(service, &properties, kCFAllocatorDefault, 0) == KERN_SUCCESS,
                  let dict = properties?.takeRetainedValue() as? [String: Any] else {
                continue
            }

            if let perfStats = dict["PerformanceStatistics"] as? [String: Any] {
                if let utilization = perfStats["GPU Core Utilization"] as? Int {
                    return Double(utilization) / 10_000_000.0
                }
                if let activity = perfStats["GPU Activity(%)"] as? Int {
                    return Double(activity)
                }
                if let deviceUtil = perfStats["Device Utilization %"] as? Int {
                    return Double(deviceUtil)
                }
            }
        }

        return estimateGPUFromFPS()
    }

    private func estimateGPUFromFPS() -> Double {
        guard currentFPS > 0 else { return 0 }
        let maxRate = Double(NSScreen.main?.maximumFramesPerSecond ?? 60)
        return min(Double(currentFPS) / maxRate * 100.0, 100.0)
    }

    private func getMemoryUsage() -> Int {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        return result == KERN_SUCCESS ? Int(info.resident_size / 1024 / 1024) : 0
    }
}
