//
//  AIControl.swift
//  openshape3d
//
//  The person's side of the control channel: one switch in Settings ▸ AI
//  Assistant, off until they turn it on, and the pairing code that an
//  assistant must present while it is on. `AgentServer` does the listening;
//  this decides WHETHER it listens and owns the code.
//
//  The code is per installation, 100 random bits, kept in the Keychain (it is
//  a credential, not a preference). It reads as four groups of five
//  characters from an alphabet without look-alikes, because a person copies
//  it into Claude Desktop's extension dialog once.
//

import Foundation
import Observation
import Security

@MainActor
@Observable
final class AIControl {
    static let shared = AIControl()

    private static let enabledKey = "aiControl.enabled"

    /// Settings ▸ AI Assistant ▸ "Let AI assistants build here".
    var isEnabled: Bool {
        didSet {
            guard isEnabled != oldValue else { return }
            UserDefaults.standard.set(isEnabled, forKey: Self.enabledKey)
            apply()
        }
    }

    private(set) var status: AgentServer.Status = .stopped
    private(set) var pairingCode: String

    /// True when a developer's `OS3D_AGENT=1` already opened the channel
    /// (DEBUG only); the switch then has nothing to start.
    private var developerStarted = false

    private init() {
        isEnabled = UserDefaults.standard.bool(forKey: Self.enabledKey)
        pairingCode = PairingCodeStore.load() ?? PairingCodeStore.replace()
        #if DEBUG
        // UI tests and video takes: a known code, and the switch already on.
        let environment = ProcessInfo.processInfo.environment
        if let fixed = environment["OS3D_AI_PAIRING_CODE"], !AgentRouter.normalizedCode(fixed).isEmpty {
            pairingCode = fixed
        }
        if environment["OS3D_AI_CONTROL"] != nil { isEnabled = environment["OS3D_AI_CONTROL"] != "0" }
        #endif
    }

    /// Called once at launch.
    func launch() {
        AgentServer.shared.observeStatus { [weak self] status in
            MainActor.assumeIsolated { self?.status = status }
        }
        developerStarted = AgentServer.shared.startIfRequested()
        apply()
    }

    private func apply() {
        guard !developerStarted else { return }
        AgentBridge.shared.framesAssistantWork = isEnabled
        if isEnabled {
            AgentServer.shared.start(pairingCode: pairingCode)
        } else {
            AgentServer.shared.stop()
        }
    }

    /// A new code: everything paired with the old one stops working at once.
    func replacePairingCode() {
        pairingCode = PairingCodeStore.replace()
        guard isEnabled, !developerStarted else { return }
        AgentServer.shared.stop()
        AgentServer.shared.start(pairingCode: pairingCode)
    }

    /// The address ChatGPT/Codex and other MCP clients connect to.
    var address: String? {
        if case let .listening(port) = status { return "http://127.0.0.1:\(port)\(AgentMCP.path)" }
        return nil
    }
}

// MARK: - The code itself

nonisolated enum PairingCodeStore {
    private static let service = "com.laan.labs.openshape3d.ai-pairing"
    private static let account = "pairing-code"
    /// Crockford's base 32: no I, L, O or U, so nothing reads two ways.
    static let alphabet = Array("0123456789ABCDEFGHJKMNPQRSTVWXYZ")

    /// 20 characters × 5 bits = 100 random bits, as `XXXXX-XXXXX-XXXXX-XXXXX`.
    static func generate() -> String {
        var bytes = [UInt8](repeating: 0, count: 20)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        precondition(status == errSecSuccess, "no secure random source")
        let characters = bytes.map { alphabet[Int($0 & 31)] }
        return stride(from: 0, to: 20, by: 5).map { String(characters[$0..<$0 + 5]) }.joined(separator: "-")
    }

    static func load() -> String? {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrService as String: service,
                                    kSecAttrAccount as String: account,
                                    kSecReturnData as String: true,
                                    kSecMatchLimit as String: kSecMatchLimitOne]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data, let code = String(data: data, encoding: .utf8),
              AgentRouter.normalizedCode(code).count == 20 else { return nil }
        return code
    }

    /// Generate, store and return a new code. If the Keychain refuses, the code
    /// still works for this launch and a new one is made next time — failing
    /// towards "pair again", never towards "no code".
    @discardableResult
    static func replace() -> String {
        let code = generate()
        let base: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                   kSecAttrService as String: service,
                                   kSecAttrAccount as String: account]
        SecItemDelete(base as CFDictionary)
        var add = base
        add[kSecValueData as String] = Data(code.utf8)
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let status = SecItemAdd(add as CFDictionary, nil)
        if status != errSecSuccess { NSLog("[agent] pairing code not saved to the Keychain (\(status))") }
        return code
    }
}

// MARK: - Where exports land

/// `os3d_export` over MCP saves into the person's Downloads folder (the
/// sandbox entitlement is `ENABLE_FILE_ACCESS_DOWNLOADS_FOLDER`): the one place
/// a non-technical person will look for "the file Claude made", and where a
/// slicer's Open dialog starts.
nonisolated enum AgentExportFolder {
    static func save(_ data: Data, requestedName: String?, format: AgentExportFormat) -> (URL?, String?) {
        let manager = FileManager.default
        guard let folder = manager.urls(for: .downloadsDirectory, in: .userDomainMask).first else {
            return (nil, "This device has no Downloads folder to save into.")
        }
        do {
            try manager.createDirectory(at: folder, withIntermediateDirectories: true)
            let name = AgentMCP.exportFileName(requested: requestedName, format: format)
            let url = unused(name, in: folder)
            try data.write(to: url, options: .atomic)
            return (url, nil)
        } catch {
            return (nil, "The file could not be saved to Downloads: \(error.localizedDescription)")
        }
    }

    /// `flowerpot.stl`, then `flowerpot 2.stl` … — never overwrite a person's file.
    static func unused(_ name: String, in folder: URL) -> URL {
        let ext = (name as NSString).pathExtension
        let stem = (name as NSString).deletingPathExtension
        var candidate = folder.appendingPathComponent(name)
        var n = 2
        while FileManager.default.fileExists(atPath: candidate.path) {
            candidate = folder.appendingPathComponent("\(stem) \(n).\(ext)")
            n += 1
        }
        return candidate
    }
}
