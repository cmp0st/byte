import XCTest

@testable import ByteClient

final class ClientChainTests: XCTestCase {

    func testClientChainInitialization() throws {
        let rootKey = Data(repeating: 0x42, count: 32)  // 32 bytes of 0x42
        let clientID = "550e8400-e29b-41d4-a716-446655440000"  // Valid UUID v4

        let clientChain = try ClientChain(root: rootKey, clientID: clientID)
        XCTAssertEqual(clientChain.clientID, clientID)
    }

    func testInvalidRootKeySize() {
        let invalidRootKey = Data(repeating: 0x42, count: 16)  // Wrong size
        let clientID = "550e8400-e29b-41d4-a716-446655440000"

        XCTAssertThrowsError(try ClientChain(root: invalidRootKey, clientID: clientID)) { error in
            guard case KeyError.invalidRootKey = error else {
                XCTFail("Expected invalidRootKey error")
                return
            }
        }
    }

    func testInvalidClientID() {
        let rootKey = Data(repeating: 0x42, count: 32)
        let invalidClientID = "not-a-uuid"

        XCTAssertThrowsError(try ClientChain(root: rootKey, clientID: invalidClientID)) { error in
            guard case KeyError.invalidClientID = error else {
                XCTFail("Expected invalidClientID error")
                return
            }
        }
    }

    func testTokenKeyDerivation() throws {
        let rootKey = Data(repeating: 0x42, count: 32)
        let clientID = "550e8400-e29b-41d4-a716-446655440000"

        let clientChain = try ClientChain(root: rootKey, clientID: clientID)
        let tokenKey = try clientChain.tokenKey()

        // Token key should be derived successfully
        XCTAssertNotNil(tokenKey)
    }

    func testEncryptDecryptRoundTrip() throws {
        let rootKey = Data(repeating: 0x42, count: 32)
        let clientID = "550e8400-e29b-41d4-a716-446655440000"
        let plaintext = "Hello, World!".data(using: .utf8)!

        let clientChain = try ClientChain(root: rootKey, clientID: clientID)

        let encrypted = try clientChain.encryptKey(plaintext)
        let decrypted = try clientChain.decryptKey(encrypted)

        XCTAssertEqual(plaintext, decrypted)
    }

    func testEncryptionProducesUniqueOutputs() throws {
        let rootKey = Data(repeating: 0x42, count: 32)
        let clientID = "550e8400-e29b-41d4-a716-446655440000"
        let plaintext = "Hello, World!".data(using: .utf8)!

        let clientChain = try ClientChain(root: rootKey, clientID: clientID)

        let encrypted1 = try clientChain.encryptKey(plaintext)
        let encrypted2 = try clientChain.encryptKey(plaintext)

        // Due to random nonces, encryptions should be different
        XCTAssertNotEqual(encrypted1, encrypted2)

        // But both should decrypt to the same plaintext
        let decrypted1 = try clientChain.decryptKey(encrypted1)
        let decrypted2 = try clientChain.decryptKey(encrypted2)

        XCTAssertEqual(decrypted1, plaintext)
        XCTAssertEqual(decrypted2, plaintext)
    }
}

