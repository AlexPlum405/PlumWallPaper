// Sources/Network/BingDailyService.swift
import Foundation

/// Bing Daily Wallpaper Service
actor BingDailyService {
    static let shared = BingDailyService()

    private let networkService = NetworkService.shared
    private let baseURL = URL(string: "https://www.bing.com")!

    private init() {}

    // MARK: - Public API

    func fetchDaily(market: String = "zh-CN", page: Int = 1, count: Int = 8, imageSize: String = "UHD") async throws -> [RemoteWallpaper] {
        let offset = max(0, page - 1) * count
        var components = URLComponents(url: baseURL.appendingPathComponent("HPImageArchive.aspx"), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "format", value: "js"),
            URLQueryItem(name: "idx", value: String(offset)),
            URLQueryItem(name: "n", value: String(count)),
            URLQueryItem(name: "mkt", value: market)
        ]

        guard let url = components?.url else { throw NetworkError.invalidResponse }

        let response = try await networkService.fetch(BingResponse.self, from: url)
        return response.images.map { image in
            let startDate = parseDate(image.startdate)
            let variant = imageVariant(for: imageSize)
            let thumbURL = URL(string: "https://www.bing.com" + image.url)
            let fullImageURL = URL(string: "https://www.bing.com" + image.urlbase + "_\(variant.suffix).jpg")

            return RemoteWallpaper(
                id: "bing_\(market)_\(variant.suffix)_\(image.startdate)",
                url: baseURL.absoluteString,
                shortURL: nil,
                thumbURL: thumbURL,
                fullImageURL: fullImageURL,
                resolution: variant.resolution,
                dimensionX: variant.width,
                dimensionY: variant.height,
                fileSize: 0,
                category: market,
                purity: "sfw",
                views: 0,
                favorites: 0,
                uploadedAt: startDate,
                tags: nil,
                colors: nil
            )
        }
    }

    // MARK: - Private Helpers

    private func imageVariant(for imageSize: String) -> (suffix: String, resolution: String, width: Int, height: Int) {
        switch imageSize {
        case "1920x1080":
            return ("1920x1080", "1920x1080", 1920, 1080)
        case "1366x768":
            return ("1366x768", "1366x768", 1366, 768)
        default:
            return ("UHD", "3840x2160", 3840, 2160)
        }
    }

    private func parseDate(_ dateString: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.date(from: dateString) ?? Date()
    }
}

// MARK: - Codable Models

private struct BingResponse: Codable {
    let images: [BingImage]
}

private struct BingImage: Codable {
    let startdate: String
    let enddate: String
    let url: String
    let urlbase: String
    let copyright: String
    let title: String
}
