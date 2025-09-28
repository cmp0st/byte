import Crypto
import Foundation
import Paseto

/// Constants matching the Go implementation
private let clientRootKeySize = 32
private let clientPasetoTokenKeySize = 32
private let clientPasetoTokenKeyDomainSeparator = "client.token.paseto-v4.v1"
private let clientKeyEncryptionKeyDomainSeparator = "client.key-encryption-key.v1"
private let clientKeyEncryptionKeySize = 32
private let clientIDUUIDVersion = 4
private let defaultTokenExpiration: TimeInterval = 30.0

/// Swift equivalent of the Go ClientChain structure
public struct ClientChain: Sendable {
    private let seed: Data
    public let clientID: String

    /// Initialize a new ClientChain
    /// - Parameters:
    ///   - root: The root key bytes (must be 32 bytes)
    ///   - clientID: The client ID (must be a valid UUID v4)
    /// - Throws: `KeyError` if the parameters are invalid
    public init(root: Data, clientID: String) throws {
        guard root.count == clientRootKeySize else {
            throw KeyError.invalidRootKey
        }

        guard let uuid = UUID(uuidString: clientID) else {
            throw KeyError.invalidClientID
        }

        // Check if it's UUID v4 by examining the version field
        let uuidData = withUnsafeBytes(of: uuid.uuid) { Data($0) }
        let versionByte = uuidData[6]
        let version = (versionByte & 0xF0) >> 4
        guard version == clientIDUUIDVersion else {
            throw KeyError.invalidClientID
        }

        self.seed = root
        self.clientID = clientID
    }

    /// Derive the PASETO token key using HKDF
    /// - Returns: A PASETO V4 symmetric key
    /// - Throws: `KeyError` if key derivation fails
    public func tokenKey() throws -> Paseto.Version4.Local.SymmetricKey {
        let salt = Data()  // Empty salt as in Go implementation
        let info = clientPasetoTokenKeyDomainSeparator.data(using: .utf8)!

        let derivedKey = HKDF<SHA256>.deriveKey(
            inputKeyMaterial: SymmetricKey(data: seed),
            salt: salt,
            info: info,
            outputByteCount: clientPasetoTokenKeySize
        )

        let keyData = derivedKey.withUnsafeBytes { Data($0) }
        return Version4.Local.SymmetricKey(material: keyData.bytes)
    }

    public func token() throws -> String {
        // Create PASETO token similar to Go implementation
        let now = Date()
        let expiration = now.addingTimeInterval(defaultTokenExpiration)

        var token = Token()
        token.expiration = expiration
        token.issuedAt = now
        token.notBefore = now

        let claims = token.claimsJSON

        let key = try self.tokenKey()
        let encrypted = Version4.Local.encrypt(
            Package(claims),
            with: key,
            implicit: self.clientID.data(using: .utf8)!,
        )

        return encrypted.asString
    }

    /// Encrypt data using the client's encryption key
    /// - Parameter plaintext: The data to encrypt
    /// - Returns: The encrypted data with nonce appended
    /// - Throws: `KeyError` if encryption fails
    public func encryptKey(_ plaintext: Data) throws -> Data {
        let encryptionKey = try deriveEncryptionKey()

        let nonce = AES.GCM.Nonce()
        do {
            let sealedBox = try AES.GCM.seal(plaintext, using: encryptionKey, nonce: nonce)

            // Manual layout: ciphertext + nonce + tag (matching Go implementation)
            var result = Data()
            result.append(sealedBox.ciphertext)
            result.append(Data(nonce))
            result.append(sealedBox.tag)

            return result
        } catch {
            throw KeyError.encryptionFailed(error.localizedDescription)
        }
    }

    /// Decrypt data using the client's encryption key
    /// - Parameter ciphertext: The encrypted data with nonce appended
    /// - Returns: The decrypted data
    /// - Throws: `KeyError` if decryption fails
    public func decryptKey(_ ciphertext: Data) throws -> Data {
        let encryptionKey = try deriveEncryptionKey()

        let nonceSize = 12  // AES.GCM.Nonce size
        let tagSize = 16  // AES.GCM tag size

        guard ciphertext.count >= nonceSize + tagSize else {
            throw KeyError.decryptionFailed(
                "Invalid ciphertext length: \(ciphertext.count), need at least \(nonceSize + tagSize)"
            )
        }

        // Extract components: ciphertext + nonce + tag
        let actualCiphertextEnd = ciphertext.count - nonceSize - tagSize
        let nonceStart = actualCiphertextEnd
        let tagStart = actualCiphertextEnd + nonceSize

        let actualCiphertext = Data(ciphertext[..<actualCiphertextEnd])
        let nonceData = Data(ciphertext[nonceStart..<tagStart])
        let tagData = Data(ciphertext[tagStart...])

        do {
            let nonce = try AES.GCM.Nonce(data: nonceData)
            let sealedBox = try AES.GCM.SealedBox(
                nonce: nonce,
                ciphertext: actualCiphertext,
                tag: tagData
            )

            return try AES.GCM.open(sealedBox, using: encryptionKey)
        } catch {
            throw KeyError.decryptionFailed(
                "Decryption failed: \(error.localizedDescription). Sizes - ciphertext: \(actualCiphertext.count), nonce: \(nonceData.count), tag: \(tagData.count)"
            )
        }
    }

    /// Derive the encryption key using HKDF
    /// - Returns: A symmetric key for encryption
    /// - Throws: `KeyError` if key derivation fails
    private func deriveEncryptionKey() throws -> Crypto.SymmetricKey {
        let salt = Data()  // Empty salt as in Go implementation
        let info = clientKeyEncryptionKeyDomainSeparator.data(using: .utf8)!

        let derivedKey = HKDF<SHA256>.deriveKey(
            inputKeyMaterial: SymmetricKey(data: seed),
            salt: salt,
            info: info,
            outputByteCount: clientKeyEncryptionKeySize
        )

        return derivedKey
    }
}
