//
//  AppState.swift
//  Byte
//
//  Created by Nathan Smith on 10/4/25.
//

import ByteClient
import Combine
import Foundation
import SwiftUI

@MainActor
class AppState: ObservableObject {
  @Published var isConfigured = false
  @Published var client: ByteClient?
  @Published var configuration: ByteClientConfiguration?
  @Published var error: String?
  @Published var isLoading = false

  private let keychainHelper = KeychainHelper.shared

  // Keychain keys
  private let serverURLKey = "serverURL"
  private let deviceIDKey = "deviceID"
  private let secretKey = "secret"

  init() {
    loadConfiguration()
  }

  func loadConfiguration() {
    guard let serverURL = keychainHelper.loadString(for: serverURLKey),
      let deviceID = keychainHelper.loadString(for: deviceIDKey),
      let secret = keychainHelper.loadString(for: secretKey)
    else {
      isConfigured = false
      return
    }

    let config = ByteClientConfiguration(
      serverURL: serverURL,
      deviceID: deviceID,
      secret: secret
    )

    do {
      let client = try ByteClient(configuration: config)
      self.client = client
      self.configuration = config
      self.isConfigured = true
      self.error = nil
    } catch {
      self.error = error.localizedDescription
      self.isConfigured = false
    }
  }

  func saveConfiguration(serverURL: String, deviceID: String, secret: String) async {
    isLoading = true
    error = nil

    do {
      // Validate configuration first
      let config = ByteClientConfiguration(
        serverURL: serverURL,
        deviceID: deviceID,
        secret: secret
      )

      try config.validate()

      // Try to create client to ensure everything works
      let client = try ByteClient(configuration: config)

      // Save to keychain
      guard keychainHelper.save(serverURL, for: serverURLKey),
        keychainHelper.save(deviceID, for: deviceIDKey),
        keychainHelper.save(secret, for: secretKey)
      else {
        throw ByteClientError.configurationError(.invalidSecret("Failed to save to keychain"))
      }

      // Update state
      self.client = client
      self.configuration = config
      self.isConfigured = true
    } catch {
      self.error = error.localizedDescription
    }

    isLoading = false
  }

  func clearConfiguration() {
    _ = keychainHelper.delete(for: serverURLKey)
    _ = keychainHelper.delete(for: deviceIDKey)
    _ = keychainHelper.delete(for: secretKey)

    client = nil
    configuration = nil
    isConfigured = false
    error = nil
  }
}
