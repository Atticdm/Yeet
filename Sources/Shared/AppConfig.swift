import Foundation

enum AppConfig {
    private static let configuration: [String: Any] = {
        guard let url = bundle.url(forResource: "Config", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil),
              let dict = plist as? [String: Any] else {
            return [:]
        }
        return dict
    }()

    private static let bundle: Bundle = {
        Bundle(for: BundleToken.self)
    }()

    /// Base URL for the Yeet backend (Railway / serverless function).
    static let backendBaseURL: URL? = {
        guard let value = configuration["backendBaseURL"] as? String else { return nil }
        return URL(string: value)
    }()

    /// Endpoint that resolves metadata + cached download link.
    static let metadataPath: String = {
        configuration["metadataPath"] as? String ?? "/get-video-link"
    }()

    /// App Group identifier shared between app & extension (required for background downloads).
    static let appGroupIdentifier: String = {
        configuration["appGroupIdentifier"] as? String ?? "group.com.atticdm.Yeet"
    }()

    /// Shared keychain access group used to store user cookies accessible by app + extension.
    static let keychainAccessGroup: String = {
        let fallback = "com.atticdm.Yeet"
        guard let prefix = (Bundle.main.object(forInfoDictionaryKey: "AppIdentifierPrefix") as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !prefix.isEmpty else {
            return fallback
        }
        return "\(prefix)com.atticdm.Yeet"
    }()

    /// Service name for Keychain entries.
    static let keychainService: String = {
        configuration["keychainService"] as? String ?? "com.atticdm.Yeet.cookies"
    }()

    /// Background URLSession identifier for large downloads.
    static let backgroundSessionIdentifier: String = {
        configuration["backgroundSessionIdentifier"] as? String ?? "com.atticdm.Yeet.background"
    }()

    /// Average network throughput in bytes/sec used to estimate download duration (~12 Mbps).
    static let assumedAverageThroughput: Double = {
        configuration["assumedAverageThroughput"] as? Double ?? (1.5 * 1024 * 1024)
    }()

    /// Threshold (seconds) over which we suggest background download / notification.
    static let longDownloadThreshold: TimeInterval = {
        configuration["longDownloadThreshold"] as? TimeInterval ?? 15
    }()
    
    /// List of supported services for authentication
    static let supportedServices: [String] = {
        configuration["supportedServices"] as? [String] ?? ["instagram", "youtube", "tiktok"]
    }()
}

private final class BundleToken {}
