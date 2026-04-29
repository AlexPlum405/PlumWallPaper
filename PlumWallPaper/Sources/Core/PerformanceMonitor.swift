import Foundation
import AppKit

@MainActor
final class PerformanceMonitor {
    static let shared = PerformanceMonitor()

    private init() {}

    func getCurrentMetrics() -> [String: Any] {
        return [
            "gpuLoad": getGPULoad(),
            "fps": getFPS(),
            "memoryMB": getMemoryUsage()
        ]
    }

    private func getGPULoad() -> Double {
        return 0.0
    }

    private func getFPS() -> Int {
        return 60
    }

    private func getMemoryUsage() -> Int {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return 0 }
        return Int(info.resident_size / 1024 / 1024)
    }
}
