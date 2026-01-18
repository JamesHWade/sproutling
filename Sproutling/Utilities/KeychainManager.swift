//
//  KeychainManager.swift
//  Sproutling
//
//  Secure storage for parent PIN using Keychain
//

import Foundation
import Security

final class KeychainManager {
    static let shared = KeychainManager()

    private let service = "com.sproutling.app"
    private let pinKey = "parent_pin"

    private init() {}

    // MARK: - PIN Management

    /// Save a 4-digit PIN to keychain
    func savePIN(_ pin: String) -> Bool {
        guard pin.count == 4, pin.allSatisfy({ $0.isNumber }) else {
            return false
        }

        // Delete existing PIN if any
        deletePIN()

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: pinKey,
            kSecValueData as String: pin.data(using: .utf8)!,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    /// Verify if the provided PIN matches the stored PIN
    func verifyPIN(_ pin: String) -> Bool {
        guard let storedPIN = getPIN() else {
            return false
        }
        return storedPIN == pin
    }

    /// Delete the stored PIN
    @discardableResult
    func deletePIN() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: pinKey
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    /// Check if a PIN has been set
    func hasPIN() -> Bool {
        return getPIN() != nil
    }

    // MARK: - Private

    private func getPIN() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: pinKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let pin = String(data: data, encoding: .utf8) else {
            return nil
        }

        return pin
    }
}
