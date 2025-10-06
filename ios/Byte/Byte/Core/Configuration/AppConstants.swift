//
//  AppConstants.swift
//  Byte
//
//  Created by Nathan Smith on 10/4/25.
//

import Foundation

/// Application-wide constants
enum AppConstants {
  /// Keychain configuration
  enum Keychain {
    static let service = "com.byte.app"

    enum Keys {
      static let serverURL = "serverURL"
      static let deviceID = "deviceID"
      static let secret = "secret"
    }
  }

  /// Photo sync configuration
  enum Photos {
    static let defaultFetchLimit = 100
    static let thumbnailSize = CGSize(width: 200, height: 200)
    static let uploadDirectory = "/photos/"
    static let defaultFilename = "photo"
  }

  /// File management configuration
  enum Files {
    static let rootPath = "/"
  }

  /// UI configuration
  enum UserInterface {
    static let thumbnailSize: CGFloat = 100
    static let cornerRadius: CGFloat = 8
    static let borderWidth: CGFloat = 3
    static let minimumGridItemSize: CGFloat = 100
  }

  /// Animation durations
  enum Animation {
    static let uploadCompletionDelay: UInt64 = 500_000_000  // 0.5 seconds in nanoseconds
  }
}
