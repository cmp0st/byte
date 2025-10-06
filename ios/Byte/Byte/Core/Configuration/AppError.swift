//
//  AppError.swift
//  Byte
//
//  Created by Nathan Smith on 10/4/25.
//

import Foundation

/// Application-level errors with user-friendly messages
enum AppError: LocalizedError {
  case keychainSaveFailed
  case keychainLoadFailed
  case keychainDeleteFailed
  case clientNotConfigured
  case invalidConfiguration
  case networkError(Error)
  case fileOperationFailed(String)
  case photoAccessDenied
  case photoLoadFailed(String)
  case invalidQRCode
  case missingQRCodeFields
  case cameraNotSupported

  var errorDescription: String? {
    switch self {
    case .keychainSaveFailed:
      return "Failed to save credentials securely"
    case .keychainLoadFailed:
      return "Failed to load stored credentials"
    case .keychainDeleteFailed:
      return "Failed to delete stored credentials"
    case .clientNotConfigured:
      return "Client not configured. Please set up the app first."
    case .invalidConfiguration:
      return "Invalid configuration. Please check your settings."
    case .networkError(let error):
      return "Network error: \(error.localizedDescription)"
    case .fileOperationFailed(let operation):
      return "File operation failed: \(operation)"
    case .photoAccessDenied:
      return "Photo library access denied. Please enable in Settings."
    case .photoLoadFailed(let identifier):
      return "Failed to load photo: \(identifier)"
    case .invalidQRCode:
      return "Invalid QR code format"
    case .missingQRCodeFields:
      return "QR code is missing required fields"
    case .cameraNotSupported:
      return "Your device does not support camera scanning"
    }
  }

  var recoverySuggestion: String? {
    switch self {
    case .keychainSaveFailed, .keychainLoadFailed, .keychainDeleteFailed:
      return "Try restarting the app or contact support if the issue persists."
    case .clientNotConfigured:
      return "Go to Setup and configure your server connection."
    case .invalidConfiguration:
      return "Verify your server URL, device ID, and secret key."
    case .networkError:
      return "Check your internet connection and try again."
    case .fileOperationFailed:
      return "Ensure you have sufficient permissions and try again."
    case .photoAccessDenied:
      return "Go to Settings > Byte and enable Photo Library access."
    case .photoLoadFailed:
      return "Try selecting a different photo."
    case .invalidQRCode, .missingQRCodeFields:
      return "Scan a valid Byte QR code from your server."
    case .cameraNotSupported:
      return "Use manual setup instead."
    }
  }
}
