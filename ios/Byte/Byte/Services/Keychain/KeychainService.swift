//
//  KeychainService.swift
//  Byte
//
//  Created by Nathan Smith on 10/4/25.
//

import Foundation
import Security

/// Production implementation of keychain service
final class KeychainService: KeychainServiceProtocol {
  // MARK: - Properties

  static let shared = KeychainService()

  private let service: String

  // MARK: - Initialization

  init(service: String = AppConstants.Keychain.service) {
    self.service = service
  }

  // MARK: - KeychainServiceProtocol

  func save(_ data: Data, for key: String) -> Bool {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: key,
      kSecAttrService as String: service,
      kSecValueData as String: data,
    ]

    // Delete any existing item first
    SecItemDelete(query as CFDictionary)

    let status = SecItemAdd(query as CFDictionary, nil)
    return status == errSecSuccess
  }

  func load(for key: String) -> Data? {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: key,
      kSecAttrService as String: service,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne,
    ]

    var dataTypeRef: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

    guard status == errSecSuccess else {
      return nil
    }

    return dataTypeRef as? Data
  }

  @discardableResult
  func delete(for key: String) -> Bool {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: key,
      kSecAttrService as String: service,
    ]

    let status = SecItemDelete(query as CFDictionary)
    return status == errSecSuccess || status == errSecItemNotFound
  }
}

// MARK: - String Convenience Methods

extension KeychainService {
  func save(_ value: String, for key: String) -> Bool {
    guard let data = value.data(using: .utf8) else {
      return false
    }
    return save(data, for: key)
  }

  func loadString(for key: String) -> String? {
    guard let data = load(for: key) else {
      return nil
    }
    return String(data: data, encoding: .utf8)
  }
}
