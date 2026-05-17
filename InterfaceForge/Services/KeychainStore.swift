import Foundation
import Security

enum KeychainItem: String {
    case aiAPIKey = "interfaceforge.ai.apiKey"
}

struct KeychainStore {
    static let shared = KeychainStore()
    private let service = "com.interfaceforge.secrets"

    func string(for item: KeychainItem) -> String {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: item.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return ""
        }
        return value
    }

    func set(_ value: String, for item: KeychainItem) {
        let account = item.rawValue
        let baseQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            SecItemDelete(baseQuery as CFDictionary)
            return
        }

        let data = Data(trimmed.utf8)
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        let status = SecItemUpdate(baseQuery as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var addQuery = baseQuery
            addQuery[kSecValueData as String] = data
            addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            SecItemAdd(addQuery as CFDictionary, nil)
        }
    }

    func migrateLegacyDefaultsKeyIfNeeded() {
        let legacyKey = KeychainItem.aiAPIKey.rawValue
        let defaults = UserDefaults.standard
        guard let legacy = defaults.string(forKey: legacyKey), !legacy.isEmpty else { return }
        if string(for: .aiAPIKey).isEmpty {
            set(legacy, for: .aiAPIKey)
        }
        defaults.removeObject(forKey: legacyKey)
    }
}
