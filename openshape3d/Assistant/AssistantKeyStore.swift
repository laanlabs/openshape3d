//
//  AssistantKeyStore.swift
//  openshape3d
//
//  The person's own Claude API key for the built-in assistant (#119). It is
//  a credential, so it lives in this device's Keychain and nowhere else: not
//  in preferences, not in a design file, not in iCloud (`ThisDeviceOnly`),
//  and it is sent only to api.anthropic.com, as the `x-api-key` header.
//

import Foundation
import Security

nonisolated enum AssistantKeyStore {
    private static let service = "com.laan.labs.openshape3d.assistant"
    private static let account = "anthropic-api-key"

    private static var base: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: service,
         kSecAttrAccount as String: account]
    }

    static func load() -> String? {
        var query = base
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
    static func save(_ key: String) -> Bool {
        SecItemDelete(base as CFDictionary)
        var add = base
        add[kSecValueData as String] = Data(key.utf8)
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let status = SecItemAdd(add as CFDictionary, nil)
        if status != errSecSuccess { NSLog("[assistant] key not saved to the Keychain (\(status))") }
        return status == errSecSuccess
    }

    static func remove() {
        SecItemDelete(base as CFDictionary)
    }

    /// What someone pasted, without the spaces and line breaks that come
    /// along from a web page or a password manager.
    static func tidy(_ pasted: String) -> String {
        String(pasted.unicodeScalars.filter { !CharacterSet.whitespacesAndNewlines.contains($0) })
    }

    /// Whether `key` looks like an API key at all: one printable ASCII word of
    /// a believable length. The real check is Anthropic accepting it; this
    /// only stops an obviously wrong paste from being stored.
    static func isPlausible(_ key: String) -> Bool {
        key.count >= 20 && key.count <= 512
            && key.unicodeScalars.allSatisfy { $0.value > 0x20 && $0.value < 0x7F }
    }
}
