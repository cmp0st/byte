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

/// Main application state manager
@MainActor
final class AppState: ObservableObject, AppStateProtocol {
  // MARK: - Published Properties

  @Published private(set) var isConfigured = false
  @Published private(set) var client: ByteClient?
  @Published private(set) var configuration: ByteClientConfiguration?
  @Published private(set) var error: String?
  @Published private(set) var isLoading = false

  // MARK: - Dependencies

  private let keychainService: KeychainServiceProtocol

  // MARK: - Initialization

  init(keychainService: KeychainServiceProtocol = KeychainService.shared) {
    self.keychainService = keychainService
    loadConfiguration()
  }

  // MARK: - Public Methods

  func loadConfiguration() {
    guard
      let serverURL = keychainService.loadString(for: AppConstants.Keychain.Keys.serverURL),
      let deviceID = keychainService.loadString(for: AppConstants.Keychain.Keys.deviceID),
      let secret = keychainService.loadString(for: AppConstants.Keychain.Keys.secret)
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
      guard
        keychainService.save(serverURL, for: AppConstants.Keychain.Keys.serverURL),
        keychainService.save(deviceID, for: AppConstants.Keychain.Keys.deviceID),
        keychainService.save(secret, for: AppConstants.Keychain.Keys.secret)
      else {
        throw AppError.keychainSaveFailed
      }

      // Update state
      self.client = client
      self.configuration = config
      self.isConfigured = true
    } catch let appError as AppError {
      self.error = appError.localizedDescription
    } catch {
      self.error = error.localizedDescription
    }

    isLoading = false
  }

  func clearConfiguration() {
    keychainService.delete(for: AppConstants.Keychain.Keys.serverURL)
    keychainService.delete(for: AppConstants.Keychain.Keys.deviceID)
    keychainService.delete(for: AppConstants.Keychain.Keys.secret)

    client = nil
    configuration = nil
    isConfigured = false
    error = nil
  }
}
