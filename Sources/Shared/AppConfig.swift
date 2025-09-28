import Foundation

enum AppConfig {
    private static let configuration: [String: Any] = {
        // Try main bundle first, then fallback to Shared module bundle
        let bundles = [Bundle.main, Bundle(for: BundleToken.self)]
        
        for bundle in bundles {
            if let url = bundle.url(forResource: "Config", withExtension: "plist"),
               let data = try? Data(contentsOf: url),
               let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil),
               let dict = plist as? [String: Any] {
                print("✅ Config.plist loaded from bundle: \(bundle.bundleIdentifier ?? "unknown")")
                return dict
            }
        }
        
        // If not found in any bundle, return empty dict instead of crashing
        print("⚠️ Config.plist not found in any bundle. Using default values.")
        return [:]
    }()

    /// Base URL for the Yeet backend (Railway / serverless function).
    static let backendBaseURL: URL? = {
        if let value = configuration["backendBaseURL"] as? String {
            return URL(string: value)
        }
        // Fallback to Railway URL if Config.plist is missing
        print("⚠️ Using fallback backend URL")
        return URL(string: "https://yeet-production-dddc.up.railway.app")
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
