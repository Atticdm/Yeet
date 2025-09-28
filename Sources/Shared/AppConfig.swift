import Foundation

enum AppConfig {
    private static let configuration: [String: Any] = {
        // Use the bundle associated with the Shared module
        let bundle = Bundle(for: BundleToken.self)
        guard let url = bundle.url(forResource: "Config", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil),
              let dict = plist as? [String: Any] else {
            // Critical error if config is missing
            fatalError("Config.plist not found or failed to load. Make sure it's included in all target memberships.")
        }
        return dict
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

    /// Shared keychain access group. Must start with your Team ID prefix.
    static let keychainAccessGroup: String = {
        guard let teamID = Bundle.main.object(forInfoDictionaryKey: "AppIdentifierPrefix") as? String, !teamID.isEmpty else {
            // This is a fallback for previews or misconfigured environments
            print("Warning: Could not determine AppIdentifierPrefix. Keychain sharing may fail.")
            return "com.atticdm.Yeet" 
        }
        return "\(teamID)com.atticdm.Yeet"
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
