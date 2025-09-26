import Foundation

/// Configuration for the Byte client
public struct ByteClientConfiguration {
    /// The server URL to connect to
    public let serverURL: String

    /// The device ID (UUID v4)
    public let deviceID: String

    /// The base64-encoded secret key for authentication
    public let secret: String

    /// Optional timeout for requests (default: 30 seconds)
    public let timeout: TimeInterval

    /// Create a new client configuration
    /// - Parameters:
    ///   - serverURL: The server URL to connect to
    ///   - deviceID: The device ID (must be a valid UUID v4)
    ///   - secret: The base64-encoded secret key
    ///   - timeout: Request timeout in seconds (default: 30)
    public init(
        serverURL: String,
        deviceID: String,
        secret: String,
        timeout: TimeInterval = 30.0
    ) {
        self.serverURL = serverURL
        self.deviceID = deviceID
        self.secret = secret
        self.timeout = timeout
    }
}

/// Errors that can occur during client configuration
public enum ByteClientConfigurationError: Error, LocalizedError {
    case invalidDeviceID(String)
    case invalidSecret(String)
    case invalidServerURL(String)

    public var errorDescription: String? {
        switch self {
        case .invalidDeviceID(let id):
            return "Invalid device ID: \(id). Must be a valid UUID v4."
        case .invalidSecret(let secret):
            return "Invalid secret: \(secret). Must be valid base64."
        case .invalidServerURL(let url):
            return "Invalid server URL: \(url)"
        }
    }
}

extension ByteClientConfiguration {
    /// Validate the configuration
    /// - Throws: `ByteClientConfigurationError` if the configuration is invalid
    public func validate() throws {
        // Validate device ID is a valid UUID v4
        guard let uuid = UUID(uuidString: deviceID),
            uuid.uuidString.lowercased() == deviceID.lowercased()
        else {
            throw ByteClientConfigurationError.invalidDeviceID(deviceID)
        }

        // Check if it's UUID v4 by examining the version field
        let uuidData = withUnsafeBytes(of: uuid.uuid) { Data($0) }
        let versionByte = uuidData[6]
        let version = (versionByte & 0xF0) >> 4
        guard version == 4 else {
            throw ByteClientConfigurationError.invalidDeviceID(deviceID)
        }

        // Validate secret is valid base64
        guard Data(base64Encoded: secret) != nil else {
            throw ByteClientConfigurationError.invalidSecret(secret)
        }

        // Validate server URL
        guard !serverURL.isEmpty, URL(string: serverURL) != nil else {
            throw ByteClientConfigurationError.invalidServerURL(serverURL)
        }
    }
}
