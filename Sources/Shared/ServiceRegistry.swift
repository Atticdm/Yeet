import Foundation

enum VideoService: String, CaseIterable, Identifiable {
    case instagram
    case youtube
    case facebook
    case linkedin

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .instagram: return "Instagram"
        case .youtube: return "YouTube"
        case .facebook: return "Facebook"
        case .linkedin: return "LinkedIn"
        }
    }

    var loginURL: URL {
        switch self {
        case .instagram: return URL(string: "https://www.instagram.com/accounts/login/")!
        case .youtube: return URL(string: "https://accounts.google.com/ServiceLogin?service=youtube")!
        case .facebook: return URL(string: "https://www.facebook.com/login.php")!
        case .linkedin: return URL(string: "https://www.linkedin.com/login")!
        }
    }

    /// Domains whose cookies should be captured as successful authentication markers.
    var requiredCookieNames: [String] {
        switch self {
        case .instagram: return ["sessionid"]
        case .youtube: return ["SID", "SAPISID", "APISID"]
        case .facebook: return ["c_user", "xs"]
        case .linkedin: return ["li_at"]
        }
    }

    /// Primary provider identifiers used by the backend and detector.
    var providerIdentifier: String {
        switch self {
        case .instagram: return "instagram"
        case .youtube: return "youtube"
        case .facebook: return "facebook"
        case .linkedin: return "linkedin"
        }
    }

    static func service(forProvider provider: String) -> VideoService? {
        Self.allCases.first { $0.providerIdentifier == provider }
    }

    static func service(forURL url: URL) -> VideoService? {
        guard let host = url.host?.lowercased() else { return nil }
        if host.contains("instagram.com") { return .instagram }
        if host.contains("youtube.com") || host.contains("youtu.be") { return .youtube }
        if host.contains("facebook.com") || host.contains("fb.watch") { return .facebook }
        if host.contains("linkedin.com") { return .linkedin }
        return nil
    }
}

struct CookiePayload: Codable {
    let name: String
    let value: String
    let domain: String
    let path: String
    let expiresDate: Date?
    let isSecure: Bool
}

extension Array where Element == CookiePayload {
    func jsonString() -> String? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

extension HTTPCookie {
    var asPayload: CookiePayload {
        CookiePayload(
            name: name,
            value: value,
            domain: domain,
            path: path,
            expiresDate: expiresDate,
            isSecure: isSecure
        )
    }
}
