import Foundation

/// Errors that can occur in the Byte client
public enum ByteClientError: Error, LocalizedError {
    case configurationError(ByteClientConfigurationError)
    case keyDerivationError(String)
    case authenticationError(String)
    case networkError(String)
    case invalidResponse(String)

    public var errorDescription: String? {
        switch self {
        case .configurationError(let configError):
            return "Configuration error: \(configError.localizedDescription)"
        case .keyDerivationError(let message):
            return "Key derivation error: \(message)"
        case .authenticationError(let message):
            return "Authentication error: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .invalidResponse(let message):
            return "Invalid response: \(message)"
        }
    }
}

/// Key-related errors
public enum KeyError: Error, LocalizedError {
    case invalidRootKey
    case invalidClientID
    case keyDerivationFailed(String)
    case encryptionFailed(String)
    case decryptionFailed(String)

    public var errorDescription: String? {
        switch self {
        case .invalidRootKey:
            return "Invalid client root key - must be 32 bytes"
        case .invalidClientID:
            return "Invalid client ID - must be a valid UUID v4"
        case .keyDerivationFailed(let message):
            return "Key derivation failed: \(message)"
        case .encryptionFailed(let message):
            return "Encryption failed: \(message)"
        case .decryptionFailed(let message):
            return "Decryption failed: \(message)"
        }
    }
}

/// Authentication-related errors
public enum AuthError: Error, LocalizedError {
    case tokenCreationFailed(String)
    case missingDeviceID
    case invalidToken(String)

    public var errorDescription: String? {
        switch self {
        case .tokenCreationFailed(let message):
            return "Token creation failed: \(message)"
        case .missingDeviceID:
            return "Missing device ID"
        case .invalidToken(let message):
            return "Invalid token: \(message)"
        }
    }
}