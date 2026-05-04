// Sources/Network/BingDailyService.swift
import Foundation

/// Bing Daily Wallpaper Service
actor BingDailyService {
    static let shared = BingDailyService()

    private let networkService = NetworkService.shared
    private let baseURL = URL(string: "https://www.bing.com")!

    private init() {}

    // MARK: - Public API

    func fetchDaily(market: String = "en-US", count: Int = 8) async throws -> [RemoteWallpaper] {
        var components = URLComponents(url: baseURL.appendingPathComponent("HPImageArchive.aspx"), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "format", value: "js"),
            URLQueryItem(name: "idx", value: "0"),
            URLQueryItem(name: "n", value: String(count)),
            URLQueryItem(name: "mkt", value: market)
        ]

        guard let url = components?.url else { throw NetworkError.invalidResponse }

        let response = try await networkService.fetch(BingResponse.self, from: url)
        return response.images.map { image in
            let startDate = parseDate(image.startdate)
            let thumbURL = URL(string: "https://www.bing.com" + image.url)
            let fullImageURL = URL(string: "https://www.bing.com" + image.urlbase + "_UHD.jpg")

            return RemoteWallpaper(
                id: "bing_\(image.startdate)",
                url: baseURL.absoluteString,
                shortURL: nil,
                thumbURL: thumbURL,
                fullImageURL: fullImageURL,
                resolution: "3840x2160",
                dimensionX: 3840,
                dimensionY: 2160,
                fileSize: 0,
                category: "general",
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
