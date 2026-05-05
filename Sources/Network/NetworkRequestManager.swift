// Sources/Network/NetworkRequestManager.swift
import Foundation

/// 网络请求管理器，提供请求去重和优先级管理
actor NetworkRequestManager {
    static let shared = NetworkRequestManager()

    private var pendingRequests: [URL: Task<Data, Error>] = [:]
    private var requestPriorities: [URL: TaskPriority] = [:]

    private init() {}

    /// 发起网络请求（自动去重）
    func fetch(url: URL, priority: TaskPriority = .medium) async throws -> Data {
        // 如果已有相同请求在进行中，直接返回
        if let pending = pendingRequests[url] {
            NSLog("[NetworkRequestManager] 复用进行中的请求: \(url.lastPathComponent)")
            return try await pending.value
        }

        // 创建新请求
        let task = Task(priority: priority) {
            defer {
                Task {
                    self.removePendingRequest(url: url)
                }
            }

            NSLog("[NetworkRequestManager] 发起新请求: \(url.lastPathComponent)")
            var request = URLRequest(url: url)
            request.timeoutInterval = 30
            request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36", forHTTPHeaderField: "User-Agent")

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw URLError(.badServerResponse)
            }

            return data
        }

        pendingRequests[url] = task
        requestPriorities[url] = priority

        return try await task.value
    }

    /// 取消指定 URL 的请求
    func cancel(url: URL) {
        pendingRequests[url]?.cancel()
        pendingRequests[url] = nil
        requestPriorities[url] = nil
        NSLog("[NetworkRequestManager] 取消请求: \(url.lastPathComponent)")
    }

    /// 取消所有低优先级请求
    func cancelLowPriorityRequests() {
        for (url, priority) in requestPriorities where priority == .low || priority == .background {
            cancel(url: url)
        }
    }

    private func removePendingRequest(url: URL) {
        pendingRequests[url] = nil
        requestPriorities[url] = nil
    }

    /// 获取当前进行中的请求数量
    var pendingRequestCount: Int {
        pendingRequests.count
    }
}
