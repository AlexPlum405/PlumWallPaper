import Foundation

@MainActor
final class APIKeyManager: ObservableObject {
    static let shared = APIKeyManager()

    enum Service: String, CaseIterable {
        case pexels
        case unsplash
        case pixabay

        var displayName: String {
            switch self {
            case .pexels: return "Pexels"
            case .unsplash: return "Unsplash"
            case .pixabay: return "Pixabay"
            }
        }

        var keyLabel: String {
            switch self {
            case .pexels: return "API Key"
            case .unsplash: return "Access Key"
            case .pixabay: return "API Key"
            }
        }

        var keyPlaceholder: String {
            switch self {
            case .pexels: return "粘贴 Pexels API Key..."
            case .unsplash: return "粘贴 Unsplash Access Key..."
            case .pixabay: return "粘贴 Pixabay API Key..."
            }
        }

        var registerURL: URL {
            switch self {
            case .pexels: return URL(string: "https://www.pexels.com/api/")!
            case .unsplash: return URL(string: "https://unsplash.com/oauth/applications")!
            case .pixabay: return URL(string: "https://pixabay.com/api/docs/")!
            }
        }

        fileprivate var defaultsKey: String {
            "apiKey_\(rawValue)"
        }
    }

    @Published private(set) var keys: [Service: String] = [:]

    private init() {
        for service in Service.allCases {
            if let stored = UserDefaults.standard.string(forKey: service.defaultsKey),
               !stored.isEmpty {
                keys[service] = stored
            }
        }
    }

    func apiKey(for service: Service) -> String? {
        keys[service]
    }

    func setAPIKey(_ key: String?, for service: Service) {
        let trimmed = key?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let trimmed, !trimmed.isEmpty {
            keys[service] = trimmed
            UserDefaults.standard.set(trimmed, forKey: service.defaultsKey)
        } else {
            keys.removeValue(forKey: service)
            UserDefaults.standard.removeObject(forKey: service.defaultsKey)
        }
    }

    func hasKey(for service: Service) -> Bool {
        keys[service] != nil
    }
}
