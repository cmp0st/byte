//
//  AppStateProtocol.swift
//  Byte
//
//  Created by Nathan Smith on 10/4/25.
//

import ByteClient
import Foundation

/// Protocol for app state management
@MainActor
protocol AppStateProtocol: ObservableObject {
  var isConfigured: Bool { get }
  var client: ByteClient? { get }
  var configuration: ByteClientConfiguration? { get }
  var error: String? { get }
  var isLoading: Bool { get }

  /// Load configuration from keychain
  func loadConfiguration()

  /// Save new configuration
  /// - Parameters:
  ///   - serverURL: The server URL
  ///   - deviceID: The device ID
  ///   - secret: The secret key
  func saveConfiguration(serverURL: String, deviceID: String, secret: String) async

  /// Clear all stored configuration
  func clearConfiguration()
}
