import Foundation
import Security

/// Secure storage service for user authentication cookies using Keychain
final class KeychainService {
    static let shared = KeychainService()
    
    private init() {}
    
    // MARK: - Cookie Storage
    
    /// Save cookies for a specific service (e.g., "instagram", "youtube")
    func saveCookies(_ cookies: [String: String], for service: String) throws {
        let data = try JSONEncoder().encode(cookies)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "\(AppConfig.keychainService).\(service)",
            kSecAttrAccount as String: "cookies",
            kSecValueData as String: data
        ]
        
        // Delete existing item first
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }
    
    /// Retrieve cookies for a specific service
    func loadCookies(for service: String) throws -> [String: String] {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "\(AppConfig.keychainService).\(service)",
            kSecAttrAccount as String: "cookies",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data else {
            throw KeychainError.itemNotFound
        }
        
        return try JSONDecoder().decode([String: String].self, from: data)
    }
    
    /// Delete cookies for a specific service
    func deleteCookies(for service: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "\(AppConfig.keychainService).\(service)",
            kSecAttrAccount as String: "cookies"
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
    
    /// Check if cookies exist for a service
    func hasCookies(for service: String) -> Bool {
        do {
            let cookies = try loadCookies(for: service)
            return !cookies.isEmpty
        } catch {
            return false
        }
    }
    
    /// List all services with stored cookies
    func listServices() -> [String] {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: AppConfig.keychainService,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let items = result as? [[String: Any]] else {
            return []
        }
        
        return items.compactMap { item in
            guard let service = item[kSecAttrService as String] as? String else { return nil }
            return service.replacingOccurrences(of: "\(AppConfig.keychainService).", with: "")
        }
    }
}

// MARK: - Errors

enum KeychainError: LocalizedError {
    case saveFailed(OSStatus)
    case loadFailed(OSStatus)
    case deleteFailed(OSStatus)
    case itemNotFound
    case encodingFailed
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let status):
            return "Failed to save to Keychain (status: \(status))"
        case .loadFailed(let status):
            return "Failed to load from Keychain (status: \(status))"
        case .deleteFailed(let status):
            return "Failed to delete from Keychain (status: \(status))"
        case .itemNotFound:
            return "Item not found in Keychain"
        case .encodingFailed:
            return "Failed to encode/decode data"
        }
    }
}