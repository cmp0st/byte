//
//  AppStateTests.swift
//  ByteTests
//
//  Created by Nathan Smith on 10/5/25.
//

import ByteClient
import XCTest

@testable import Byte

@MainActor
final class AppStateTests: XCTestCase {
  // MARK: - Properties

  var sut: AppState!
  var mockKeychainService: MockKeychainService!

  // MARK: - Lifecycle

  override func setUp() {
    super.setUp()
    mockKeychainService = MockKeychainService()
    sut = AppState(keychainService: mockKeychainService)
  }

  override func tearDown() {
    sut = nil
    mockKeychainService = nil
    super.tearDown()
  }

  // MARK: - Tests

  func testInitialState() {
    // Then
    XCTAssertFalse(sut.isConfigured)
    XCTAssertNil(sut.client)
    XCTAssertNil(sut.configuration)
    XCTAssertFalse(sut.isLoading)
  }

  func testLoadConfiguration_WithValidCredentials_ConfiguresClient() {
    // Given
    mockKeychainService.mockData = [
      AppConstants.Keychain.Keys.serverURL: "https://example.com",
      AppConstants.Keychain.Keys.deviceID: UUID().uuidString,
      AppConstants.Keychain.Keys.secret: "validBase64Secret==",
    ]

    // When
    sut.loadConfiguration()

    // Then
    XCTAssertTrue(sut.isConfigured)
    XCTAssertNotNil(sut.client)
    XCTAssertNotNil(sut.configuration)
    XCTAssertNil(sut.error)
  }

  func testLoadConfiguration_WithMissingCredentials_DoesNotConfigure() {
    // Given
    mockKeychainService.mockData = [:]  // No credentials

    // When
    sut.loadConfiguration()

    // Then
    XCTAssertFalse(sut.isConfigured)
    XCTAssertNil(sut.client)
    XCTAssertNil(sut.configuration)
  }

  func testSaveConfiguration_WithValidData_SavesSuccessfully() async {
    // Given
    mockKeychainService.shouldSucceed = true
    let serverURL = "https://example.com"
    let deviceID = UUID().uuidString
    let secret = "validBase64Secret=="

    // When
    await sut.saveConfiguration(
      serverURL: serverURL,
      deviceID: deviceID,
      secret: secret
    )

    // Then
    XCTAssertTrue(sut.isConfigured)
    XCTAssertNotNil(sut.client)
    XCTAssertNotNil(sut.configuration)
    XCTAssertNil(sut.error)
    XCTAssertFalse(sut.isLoading)

    // Verify keychain was called
    XCTAssertEqual(
      mockKeychainService.mockData[AppConstants.Keychain.Keys.serverURL],
      serverURL
    )
    XCTAssertEqual(
      mockKeychainService.mockData[AppConstants.Keychain.Keys.deviceID],
      deviceID
    )
    XCTAssertEqual(
      mockKeychainService.mockData[AppConstants.Keychain.Keys.secret],
      secret
    )
  }

  func testSaveConfiguration_WithKeychainFailure_SetsError() async {
    // Given
    mockKeychainService.shouldSucceed = false

    // When
    await sut.saveConfiguration(
      serverURL: "https://example.com",
      deviceID: UUID().uuidString,
      secret: "secret"
    )

    // Then
    XCTAssertFalse(sut.isConfigured)
    XCTAssertNotNil(sut.error)
    XCTAssertFalse(sut.isLoading)
  }

  func testClearConfiguration_RemovesAllData() {
    // Given - Set up configured state
    mockKeychainService.mockData = [
      AppConstants.Keychain.Keys.serverURL: "https://example.com",
      AppConstants.Keychain.Keys.deviceID: UUID().uuidString,
      AppConstants.Keychain.Keys.secret: "secret",
    ]
    sut.loadConfiguration()
    XCTAssertTrue(sut.isConfigured)

    // When
    sut.clearConfiguration()

    // Then
    XCTAssertFalse(sut.isConfigured)
    XCTAssertNil(sut.client)
    XCTAssertNil(sut.configuration)
    XCTAssertNil(sut.error)
    XCTAssertTrue(mockKeychainService.mockData.isEmpty)
  }
}
