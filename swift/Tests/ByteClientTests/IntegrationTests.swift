import Connect
import XCTest

@testable import ByteClient

/// Integration tests that connect to a real server
///
/// To run these tests:
/// 1. Start your server on localhost:8080
/// 2. Set the environment variables:
///    - BYTE_CLIENT_ID (UUID v4)
///    - BYTE_CLIENT_SECRET (base64 encoded)
/// 3. Run: swift test --filter IntegrationTests
///
/// Example:
/// export BYTE_CLIENT_ID="550e8400-e29b-41d4-a716-446655440000"
/// export BYTE_CLIENT_SECRET="dGVzdGtleWZvcmJ5dGVzZXJ2ZXJjbGllbnR0ZXN0"
/// swift test --filter IntegrationTests
final class IntegrationTests: XCTestCase {

    private var client: ByteClient?

    override func setUp() async throws {
        // Only run if environment variables are set
        guard let clientId = ProcessInfo.processInfo.environment["BYTE_CLIENT_ID"],
            let secret = ProcessInfo.processInfo.environment["BYTE_CLIENT_SECRET"]
        else {
            throw XCTSkip(
                "Integration tests require BYTE_CLIENT_ID and BYTE_CLIENT_SECRET environment variables"
            )
        }

        let config = ByteClientConfiguration(
            serverURL: "http://localhost:8080",
            deviceID: clientId,
            secret: secret,
            timeout: 30.0
        )

        // Validate configuration
        try config.validate()

        // Create client
        self.client = try ByteClient(configuration: config)
    }

    func testListRootDirectory() async throws {
        guard let client = client else {
            XCTFail("Client not initialized")
            return
        }

        print("🔧 Testing connection to server...")

        let request = Files_V1_ListDirectoryRequest.with { req in
            req.path = "/"
        }

        let response = await client.files.listDirectory(request: request, headers: [:])

        switch response.result {
        case .success(let listResponse):
            print("✅ Successfully listed root directory!")
            print("📁 Found \(listResponse.entries.count) entries:")
            for entry in listResponse.entries.prefix(5) {  // Show first 5 entries
                let type = entry.isDir ? "📂" : "📄"
                print("   \(type) \(entry.name) (\(entry.size) bytes)")
            }
            if listResponse.entries.count > 5 {
                print("   ... and \(listResponse.entries.count - 5) more entries")
            }

        case .failure(let error):
            XCTFail("Failed to list directory: \(error)")
        }
    }

    func testCreateAndListDirectory() async throws {
        guard let client = client else {
            XCTFail("Client not initialized")
            return
        }

        let testDirName = "test-swift-client-\(UUID().uuidString.prefix(8))"
        let testPath = "/\(testDirName)"

        print("🔧 Testing directory creation...")

        // Create directory
        let createRequest = Files_V1_MakeDirectoryRequest.with { req in
            req.path = testPath
        }

        let createResponse = await client.files.makeDirectory(request: createRequest, headers: [:])

        switch createResponse.result {
        case .success:
            print("✅ Successfully created directory: \(testPath)")

            // List parent directory to verify it exists
            let listRequest = Files_V1_ListDirectoryRequest.with { req in
                req.path = "/"
            }

            let listResponse = await client.files.listDirectory(request: listRequest, headers: [:])

            switch listResponse.result {
            case .success(let listResult):
                let foundDir = listResult.entries.contains { entry in
                    entry.name == testDirName && entry.isDir
                }

                if foundDir {
                    print("✅ Directory appears in listing!")
                } else {
                    XCTFail("Created directory not found in listing")
                }

            case .failure(let error):
                XCTFail("Failed to list directory after creation: \(error)")
            }

        case .failure(let error):
            XCTFail("Failed to create directory: \(error)")
        }
    }

    func testDeviceOperations() async throws {
        guard let client = client else {
            XCTFail("Client not initialized")
            return
        }

        print("🔧 Testing device operations...")

        // List devices
        let listRequest = Devices_V1_ListDevicesRequest()
        let listResponse = await client.devices.listDevices(request: listRequest, headers: [:])

        switch listResponse.result {
        case .success(let devices):
            print("✅ Successfully listed devices!")
            print("📱 Found \(devices.devices.count) devices:")
            for device in devices.devices.prefix(3) {  // Show first 3 devices
                print("   • Device (ID: \(device.id.prefix(8))...)")
            }
            if devices.devices.count > 3 {
                print("   ... and \(devices.devices.count - 3) more devices")
            }

        case .failure(let error):
            XCTFail("Failed to list devices: \(error)")
        }
    }

    func testAuthenticationHeaders() async throws {
        guard let client = client else {
            XCTFail("Client not initialized")
            return
        }

        print("🔧 Testing authentication...")

        // Make a simple request that will test authentication
        let request = Files_V1_ListDirectoryRequest.with { req in
            req.path = "/"
        }

        let response = await client.files.listDirectory(request: request, headers: [:])

        switch response.result {
        case .success:
            print("✅ Authentication successful!")
        case .failure(let error):
            // Check if it's an authentication error
            if error.code == .unauthenticated {
                XCTFail(
                    "Authentication failed - check your credentials: \(error.message ?? "No message")"
                )
            } else {
                XCTFail("Request failed with non-auth error: \(error)")
            }
        }
    }

    func testClientConfiguration() async throws {
        let config = ByteClientConfiguration(
            serverURL: "http://localhost:8080",
            deviceID: "550e8400-e29b-41d4-a716-446655440000",
            secret: "dGVzdA==",
            timeout: 30.0
        )

        XCTAssertNoThrow(try config.validate())

        let client = try ByteClient(configuration: config)
        XCTAssertEqual(client.clientID, "550e8400-e29b-41d4-a716-446655440000")

        print("✅ Client configuration and initialization successful!")
    }
}
