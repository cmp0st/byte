//
//  KeychainServiceProtocol.swift
//  Byte
//
//  Created by Nathan Smith on 10/4/25.
//

import Foundation

/// Protocol for keychain operations to enable testing and dependency injection
protocol KeychainServiceProtocol {
  /// Save data to keychain
  /// - Parameters:
  ///   - data: The data to save
  ///   - key: The key to store the data under
  /// - Returns: True if successful, false otherwise
  func save(_ data: Data, for key: String) -> Bool

  /// Load data from keychain
  /// - Parameter key: The key to retrieve data for
  /// - Returns: The stored data, or nil if not found
  func load(for key: String) -> Data?

  /// Delete data from keychain
  /// - Parameter key: The key to delete
  /// - Returns: True if successful, false otherwise
  @discardableResult
  func delete(for key: String) -> Bool

  /// Save string to keychain
  /// - Parameters:
  ///   - value: The string to save
  ///   - key: The key to store the string under
  /// - Returns: True if successful, false otherwise
  func save(_ value: String, for key: String) -> Bool

  /// Load string from keychain
  /// - Parameter key: The key to retrieve string for
  /// - Returns: The stored string, or nil if not found
  func loadString(for key: String) -> String?
}
