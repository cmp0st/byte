import XCTest

@testable import ByteClient

final class ConfigurationTests: XCTestCase {

    func testValidConfiguration() throws {
        let config = ByteClientConfiguration(
            serverURL: "https://example.com",
            deviceID: "550e8400-e29b-41d4-a716-446655440000",  // Valid UUID v4
            secret: "dGVzdA==",  // "test" in base64
            timeout: 30.0
        )

        XCTAssertNoThrow(try config.validate())
    }

    func testInvalidDeviceID() {
        let config = ByteClientConfiguration(
            serverURL: "https://example.com",
            deviceID: "not-a-uuid",
            secret: "dGVzdA==",
            timeout: 30.0
        )

        XCTAssertThrowsError(try config.validate()) { error in
            guard case ByteClientConfigurationError.invalidDeviceID = error else {
                XCTFail("Expected invalidDeviceID error")
                return
            }
        }
    }

    func testInvalidSecret() {
        let config = ByteClientConfiguration(
            serverURL: "https://example.com",
            deviceID: "550e8400-e29b-41d4-a716-446655440000",
            secret: "not-base64!@#",
            timeout: 30.0
        )

        XCTAssertThrowsError(try config.validate()) { error in
            guard case ByteClientConfigurationError.invalidSecret = error else {
                XCTFail("Expected invalidSecret error")
                return
            }
        }
    }

    func testInvalidServerURL() {
        let config = ByteClientConfiguration(
            serverURL: "",
            deviceID: "550e8400-e29b-41d4-a716-446655440000",
            secret: "dGVzdA==",
            timeout: 30.0
        )

        XCTAssertThrowsError(try config.validate()) { error in
            guard case ByteClientConfigurationError.invalidServerURL = error else {
                XCTFail("Expected invalidServerURL error")
                return
            }
        }
    }
}

