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

    /// 下载文件到本地（支持断点续传，手动重试避免进度重置）
    func downloadFile(
        from url: URL,
        to destinationURL: URL,
        headers: [String: String] = [:],
        progressHandler: (@Sendable (Double) -> Void)? = nil,
        retryConfig: RetryConfiguration? = nil
    ) async throws {
        let config = effectiveRetryConfiguration(retryConfig)
        let fileManager = FileManager.default
        var lastError: Error?

        // 首次尝试：检查 URLCache 是否有完整缓存
        if let cachedData = try? await checkCache(for: url) {
            NSLog("[NetworkService] 使用缓存数据，大小: \(cachedData.count) 字节")
            try cachedData.write(to: destinationURL, options: .atomic)
            progressHandler?(1.0)
            return
        }

        for attempt in 1...(config.maxRetries + 1) {
            // 检查是否有部分下载的文件
            var existingSize: Int64 = 0
            var resumeHeaders = headers

            // 只在重试时才尝试断点续传（首次下载删除旧文件）
            if attempt > 1 && fileManager.fileExists(atPath: destinationURL.path) {
                if let attributes = try? fileManager.attributesOfItem(atPath: destinationURL.path),
                   let size = attributes[.size] as? Int64, size > 0 {
                    existingSize = size
                    // 添加 Range 头支持断点续传
                    resumeHeaders["Range"] = "bytes=\(existingSize)-"
                    NSLog("[NetworkService] 重试 #\(attempt)，尝试从 \(existingSize) 字节处续传")
                }
            } else if attempt == 1 {
                // 首次下载，删除可能存在的旧文件
                try? fileManager.removeItem(at: destinationURL)
            }

            do {
                let data = try await self.fetchDataInternal(
                    from: url,
                    headers: resumeHeaders,
                    attempt: attempt,
                    progressHandler: { progress in
                        progressHandler?(progress)
                    },
                    useCache: false,
                    resumeOffset: existingSize
                )

                // 如果是续传，追加数据；否则覆盖写入
                if existingSize > 0 {
                    if let fileHandle = try? FileHandle(forWritingTo: destinationURL) {
                        fileHandle.seekToEndOfFile()
                        fileHandle.write(data)
                        try? fileHandle.close()
                        NSLog("[NetworkService] 续传完成，追加了 \(data.count) 字节")
                    } else {
                        // 如果无法打开文件句柄，删除旧文件重新下载
                        try? fileManager.removeItem(at: destinationURL)
                        try data.write(to: destinationURL, options: .atomic)
                    }
                } else {
                    try data.write(to: destinationURL, options: .atomic)
                }

                // 下载成功，返回
                if attempt > 1 {
                    NSLog("[NetworkService] 重试成功，attempt=\(attempt)")
                }
                return

            } catch let error as NetworkError {
                lastError = error

                // 如果是 416 错误（Range Not Satisfiable），删除本地文件后重试
                if case .httpError(416) = error {
                    NSLog("[NetworkService] 收到 416 错误，删除本地文件")
                    try? fileManager.removeItem(at: destinationURL)
                }

                // 检查是否可重试
                guard error.isRetryable else {
                    NSLog("[NetworkService] 错误不可重试: \(error)")
                    throw error
                }

                // 检查是否还有重试机会
                guard attempt <= config.maxRetries else {
                    NSLog("[NetworkService] 达到最大重试次数 (\(config.maxRetries))")
                    throw error
                }

                // 计算延迟时间
                let delay = config.delayForRetry(attempt: attempt)
                NSLog("[NetworkService] 将在 \(delay)s 后重试 (\(attempt)/\(config.maxRetries))")

                // 等待后重试
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

            } catch {
                lastError = error
                throw error
            }
        }

        // 如果所有重试都失败，抛出最后一个错误
        if let error = lastError {
            throw error
        }
    }

    // MARK: - Internal Implementation

    private func fetchDataInternal(
        from url: URL,
        headers: [String: String] = [:],
        attempt: Int = 1,
        progressHandler: (@Sendable (Double) -> Void)? = nil,
        useCache: Bool = true,
        resumeOffset: Int64 = 0
    ) async throws -> Data {

        var request = URLRequest(url: url)
        if !useCache {
            request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        }
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        return try await performRequest(request: request, progressHandler: progressHandler, resumeOffset: resumeOffset)
    }

    /// 执行网络请求
    private func performRequest(
        request: URLRequest,
        progressHandler: (@Sendable (Double) -> Void)? = nil,
        resumeOffset: Int64 = 0
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
            let totalLength = resumeOffset + expectedLength
            let chunkSize = 64 * 1024
            var receivedLength: Int64 = resumeOffset
            var data = Data()
            var buffer: [UInt8] = []
            buffer.reserveCapacity(chunkSize)

            var lastReportedProgress: Double = 0
            let progressThreshold = 0.01

            // 初始进度考虑已下载的部分
            if totalLength > 0 {
                let initialProgress = Double(resumeOffset) / Double(totalLength)
                progressHandler(initialProgress)
                lastReportedProgress = initialProgress
            } else {
                progressHandler(0.08)
            }

            for try await byte in bytes {
                buffer.append(byte)

                if buffer.count >= chunkSize {
                    data.append(contentsOf: buffer)
                    receivedLength += Int64(buffer.count)
                    buffer.removeAll(keepingCapacity: true)

                    if totalLength > 0 {
                        let currentProgress = min(max(Double(receivedLength) / Double(totalLength), 0.0), 1.0)
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

            if totalLength > 0 {
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

    /// 检查 URLCache 中是否有完整的缓存数据
    private func checkCache(for url: URL) async throws -> Data? {
        let request = URLRequest(url: url, cachePolicy: .returnCacheDataDontLoad)

        // 尝试从缓存获取
        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                return nil
            }

            // 验证数据完整性：检查 Content-Length
            if let contentLength = httpResponse.value(forHTTPHeaderField: "Content-Length"),
               let expectedSize = Int64(contentLength),
               Int64(data.count) != expectedSize {
                NSLog("[NetworkService] 缓存数据不完整: \(data.count)/\(expectedSize) 字节")
                return nil
            }

            NSLog("[NetworkService] 找到完整缓存: \(data.count) 字节")
            return data
        } catch {
            // 缓存未命中或其他错误
            return nil
        }
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
