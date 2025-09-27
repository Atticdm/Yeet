import Foundation

enum AppConfig {
    /// Base URL for the Yeet backend (Railway / serverless function).
    static let backendBaseURL: URL? = URL(string: "https://zoological-rejoicing-production.up.railway.app")

    /// Endpoint that resolves metadata + cached download link.
    static let metadataPath = "/get-video-link"

    /// App Group identifier shared between app & extension (required for background downloads).
    static let appGroupIdentifier = "group.com.atticdm.Yeet"

    /// Background URLSession identifier for large downloads.
    static let backgroundSessionIdentifier = "com.atticdm.Yeet.background"

    /// Average network throughput in bytes/sec used to estimate download duration (~12 Mbps).
    static let assumedAverageThroughput: Double = 1.5 * 1024 * 1024

    /// Threshold (seconds) over which we suggest background download / notification.
    static let longDownloadThreshold: TimeInterval = 15
}
