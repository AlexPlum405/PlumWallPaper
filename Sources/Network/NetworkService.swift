// Sources/Network/NetworkService.swift
import Foundation

actor NetworkService {
    static let shared = NetworkService()

    private let session: URLSession
    private let cache: URLCache

    // MARK: - Retry Configuration
    private var defaultRetryConfig: RetryConfiguration = .default

    private init() {
        // 配置 URLCache
        let cache = URLCache(
            memoryCapacity: 50_000_000,  // 50 MB 内存缓存
            diskCapacity: 200_000_000,   // 200 MB 磁盘缓存
            diskPath: "PlumWallpaperCache"
        )
        self.cache = cache

        // 配置 URLSession
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.urlCache = cache
        config.allowsCellularAccess = true
        config.waitsForConnectivity = true
        config.isDiscretionary = false

        self.session = URLSession(configuration: config)
    }

    // MARK: - Retry Configuration

    /// 设置默认重试配置
    func setDefaultRetryConfiguration(_ config: RetryConfiguration) {
        self.defaultRetryConfig = config
    }

    /// 获取当前有效的重试配置
    private func effectiveRetryConfiguration(_ customConfig: RetryConfiguration? = nil) -> RetryConfiguration {
        customConfig ?? defaultRetryConfig
    }

    // MARK: - Public API with Retry

    /// 获取 API 数据（禁用缓存，每次重新请求）
    func fetch<T: Decodable>(
        _ type: T.Type,
        from url: URL,
        headers: [String: String] = [:],
        retryConfig: RetryConfiguration? = nil
    ) async throws -> T {
        let config = effectiveRetryConfiguration(retryConfig)

        return try await executeWithRetry(config: config, operation: { attempt in
            let data = try await self.fetchDataInternal(from: url, headers: headers, attempt: attempt, useCache: false)

            let decoder = JSONDecoder()
            // Wallhaven API 使用自定义日期格式: "2026-05-02 05:53:28"
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            decoder.dateDecodingStrategy = .formatted(dateFormatter)

            do {
                let result = try decoder.decode(T.self, from: data)
                return result
            } catch {
                print("[NetworkService] Decoding error: \(error)")
                if let decodingError = error as? DecodingError {
                    print("[NetworkService] Detailed error: \(decodingError)")
                }
                throw NetworkError.decodingError
            }
        })
    }

    // MARK: - Data Fetching with Retry

    /// 获取数据（禁用缓存，每次重新请求）
    func fetchData(
        from url: URL,
        headers: [String: String] = [:],
        progressHandler: (@Sendable (Double) -> Void)? = nil,
        retryConfig: RetryConfiguration? = nil
    ) async throws -> Data {
        let config = effectiveRetryConfiguration(retryConfig)

        return try await executeWithRetry(config: config) { attempt in
            try await self.fetchDataInternal(from: url, headers: headers, attempt: attempt, progressHandler: progressHandler, useCache: false)
        }
    }

    /// 下载文件到本地
    func downloadFile(
        from url: URL,
        to destinationURL: URL,
        headers: [String: String] = [:],
        progressHandler: (@Sendable (Double) -> Void)? = nil,
        retryConfig: RetryConfiguration? = nil
    ) async throws {
        let config = effectiveRetryConfiguration(retryConfig)

        try await executeWithRetry(config: config) { attempt in
            let data = try await self.fetchDataInternal(from: url, headers: headers, attempt: attempt, progressHandler: progressHandler, useCache: false)
            try data.write(to: destinationURL, options: .atomic)
        }
    }

    // MARK: - Internal Implementation

    private func fetchDataInternal(
        from url: URL,
        headers: [String: String] = [:],
        attempt: Int = 1,
        progressHandler: (@Sendable (Double) -> Void)? = nil,
        useCache: Bool = true
    ) async throws -> Data {

        var request = URLRequest(url: url)
        if !useCache {
            request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        }
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        return try await performRequest(request: request, progressHandler: progressHandler)
    }

    /// 执行网络请求
    private func performRequest(
        request: URLRequest,
        progressHandler: (@Sendable (Double) -> Void)? = nil
    ) async throws -> Data {

        if let progressHandler {
            let (bytes, response) = try await session.bytes(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                if httpResponse.statusCode >= 500 {
                    throw NetworkError.serverError(httpResponse.statusCode)
                } else {
                    throw NetworkError.httpError(httpResponse.statusCode)
                }
            }

            let expectedLength = response.expectedContentLength
            let chunkSize = 64 * 1024
            var receivedLength: Int64 = 0
            var data = Data()
            var buffer: [UInt8] = []
            buffer.reserveCapacity(chunkSize)

            var lastReportedProgress: Double = 0
            let progressThreshold = 0.01

            progressHandler(expectedLength > 0 ? 0.0 : 0.08)

            for try await byte in bytes {
                buffer.append(byte)

                if buffer.count >= chunkSize {
                    data.append(contentsOf: buffer)
                    receivedLength += Int64(buffer.count)
                    buffer.removeAll(keepingCapacity: true)

                    if expectedLength > 0 {
                        let currentProgress = min(max(Double(receivedLength) / Double(expectedLength), 0.0), 1.0)
                        if currentProgress - lastReportedProgress >= progressThreshold || currentProgress >= 0.99 {
                            lastReportedProgress = currentProgress
                            progressHandler(currentProgress)
                        }
                    }
                }
            }

            if !buffer.isEmpty {
                data.append(contentsOf: buffer)
                receivedLength += Int64(buffer.count)
            }

            if expectedLength > 0 {
                progressHandler(1.0)
            }

            return data
        } else {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                if httpResponse.statusCode >= 500 {
                    throw NetworkError.serverError(httpResponse.statusCode)
                } else {
                    throw NetworkError.httpError(httpResponse.statusCode)
                }
            }

            return data
        }
    }

    /// 获取字符串数据（用于 HTML 页面）
    func fetchString(
        from url: URL,
        headers: [String: String] = [:],
        retryConfig: RetryConfiguration? = nil
    ) async throws -> String {
        let data = try await fetchData(from: url, headers: headers, retryConfig: retryConfig)
        return String(decoding: data, as: UTF8.self)
    }

    // MARK: - Retry Logic

    private func executeWithRetry<T>(
        config: RetryConfiguration,
        operation: @Sendable (Int) async throws -> T
    ) async throws -> T {
        var lastError: Error?

        for attempt in 1...(config.maxRetries + 1) {
            do {
                let result = try await operation(attempt)
                if attempt > 1 {
                    print("[NetworkService] Retry succeeded on attempt \(attempt)")
                }
                return result
            } catch {
                lastError = error

                // 检查是否可重试
                guard error.isRetryable else {
                    print("[NetworkService] Error is not retryable: \(error)")
                    throw error
                }

                // 检查是否还有重试机会
                guard attempt <= config.maxRetries else {
                    print("[NetworkService] Max retries (\(config.maxRetries)) exceeded")
                    throw error
                }

                // 计算延迟时间
                let delay = config.delayForRetry(attempt: attempt)
                print("[NetworkService] Retry attempt \(attempt)/\(config.maxRetries) after \(delay)s delay")

                // 等待后重试
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }

        throw lastError ?? NetworkError.networkError(NSError(domain: "NetworkService", code: -1))
    }
}
