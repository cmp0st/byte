//
//  MockKeychainService.swift
//  ByteTests
//
//  Created by Nathan Smith on 10/5/25.
//

import Foundation

@testable import Byte

/// Mock keychain service for testing
final class MockKeychainService: KeychainServiceProtocol {
  // MARK: - Properties

  var mockData: [String: String] = [:]
  var shouldSucceed = true

  // MARK: - KeychainServiceProtocol

  func save(_ data: Data, for key: String) -> Bool {
    guard shouldSucceed else { return false }
    if let string = String(data: data, encoding: .utf8) {
      mockData[key] = string
    }
    return true
  }

  func load(for key: String) -> Data? {
    mockData[key]?.data(using: .utf8)
  }

  func delete(for key: String) -> Bool {
    mockData.removeValue(forKey: key)
    return true
  }

  func save(_ value: String, for key: String) -> Bool {
    guard shouldSucceed else { return false }
    mockData[key] = value
    return true
  }

  func loadString(for key: String) -> String? {
    mockData[key]
  }
}
