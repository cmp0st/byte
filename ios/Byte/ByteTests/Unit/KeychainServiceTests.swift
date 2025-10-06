//
//  KeychainServiceTests.swift
//  ByteTests
//
//  Created by Nathan Smith on 10/5/25.
//

import XCTest

@testable import Byte

final class KeychainServiceTests: XCTestCase {
  // MARK: - Properties

  var sut: KeychainService!
  let testService = "com.byte.test"

  // MARK: - Lifecycle

  override func setUp() {
    super.setUp()
    sut = KeychainService(service: testService)
    // Clean up any existing test data
    _ = sut.delete(for: "testKey")
  }

  override func tearDown() {
    // Clean up test data
    _ = sut.delete(for: "testKey")
    sut = nil
    super.tearDown()
  }

  // MARK: - Tests

  func testSaveAndLoad_Data() {
    // Given
    let testData = "test data".data(using: .utf8)!
    let key = "testKey"

    // When
    let saveResult = sut.save(testData, for: key)
    let loadedData = sut.load(for: key)

    // Then
    XCTAssertTrue(saveResult)
    XCTAssertEqual(loadedData, testData)
  }

  func testSaveAndLoad_String() {
    // Given
    let testString = "test string"
    let key = "testKey"

    // When
    let saveResult = sut.save(testString, for: key)
    let loadedString = sut.loadString(for: key)

    // Then
    XCTAssertTrue(saveResult)
    XCTAssertEqual(loadedString, testString)
  }

  func testLoad_NonExistentKey_ReturnsNil() {
    // Given
    let key = "nonExistentKey"

    // When
    let result = sut.load(for: key)

    // Then
    XCTAssertNil(result)
  }

  func testDelete_ExistingKey_ReturnsTrue() {
    // Given
    let testData = "test data".data(using: .utf8)!
    let key = "testKey"
    _ = sut.save(testData, for: key)

    // When
    let deleteResult = sut.delete(for: key)
    let loadResult = sut.load(for: key)

    // Then
    XCTAssertTrue(deleteResult)
    XCTAssertNil(loadResult)
  }

  func testDelete_NonExistentKey_ReturnsTrue() {
    // Given
    let key = "nonExistentKey"

    // When
    let result = sut.delete(for: key)

    // Then
    XCTAssertTrue(result)  // Should succeed even if key doesn't exist
  }

  func testSave_OverwritesExistingValue() {
    // Given
    let key = "testKey"
    let originalValue = "original"
    let newValue = "updated"

    // When
    _ = sut.save(originalValue, for: key)
    _ = sut.save(newValue, for: key)
    let result = sut.loadString(for: key)

    // Then
    XCTAssertEqual(result, newValue)
  }
}
