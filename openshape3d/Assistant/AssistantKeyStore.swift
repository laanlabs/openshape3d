//
//  AssistantKeyStore.swift
//  openshape3d
//
//  The person's own API keys for the built-in assistant (#119): one per
//  provider they use (Claude, OpenAI, Gemini). Each is a credential, so it
//  lives in this device's Keychain and nowhere else: not in preferences, not
//  in a design file, not in iCloud (`ThisDeviceOnly`). A key is sent only to
//  the provider it belongs to, in that provider's own header.
//

import Foundation
import Security

nonisolated enum AssistantKeyStore {
    private static let service = "com.laan.labs.openshape3d.assistant"

    /// The Keychain account a provider's key is filed under.
    static func account(for provider: AssistantProvider) -> String {
        switch provider {
        case .anthropic: return "anthropic-api-key"
        case .openai: return "openai-api-key"
        case .google: return "google-api-key"
        }
    }

    private static func base(_ provider: AssistantProvider) -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: service,
         kSecAttrAccount as String: account(for: provider)]
    }

    static func load(_ provider: AssistantProvider) -> String? {
        var query = base(provider)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data, let key = String(data: data, encoding: .utf8),
              !key.isEmpty else { return nil }
        return key
    }

    /// Store `key`, replacing any earlier one. False when the Keychain refused.
    @discardableResult
    static func save(_ key: String, for provider: AssistantProvider) -> Bool {
        SecItemDelete(base(provider) as CFDictionary)
        var add = base(provider)
        add[kSecValueData as String] = Data(key.utf8)
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let status = SecItemAdd(add as CFDictionary, nil)
        if status != errSecSuccess { NSLog("[assistant] key not saved to the Keychain (\(status))") }
        return status == errSecSuccess
    }

    static func remove(_ provider: AssistantProvider) {
        SecItemDelete(base(provider) as CFDictionary)
    }

    /// What someone pasted, without the spaces and line breaks that come
    /// along from a web page or a password manager.
    static func tidy(_ pasted: String) -> String {
        String(pasted.unicodeScalars.filter { !CharacterSet.whitespacesAndNewlines.contains($0) })
    }

    /// Whether `key` looks like an API key at all: one printable ASCII word of
    /// a believable length. The real check is the provider accepting it;
    /// this only stops an obviously wrong paste from being stored.
    static func isPlausible(_ key: String) -> Bool {
        key.count >= 20 && key.count <= 512
            && key.unicodeScalars.allSatisfy { $0.value > 0x20 && $0.value < 0x7F }
    }
}
