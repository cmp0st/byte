import ArgumentParser
import ByteClient
import Crypto
import Foundation

struct DebugCommand: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "debug",
    abstract: "Debug utilities for the Byte Swift client",
    subcommands: [GenerateCommand.self]
  )
}

struct GenerateCommand: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "generate",
    abstract: "Generate utilities",
    subcommands: [GenerateTokenCommand.self]
  )
}

struct GenerateTokenCommand: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "token",
    abstract: "Generate a PASETO token and display the derived encryption key"
  )

  @Argument(help: "Root key as base64 string")
  var rootKeyBase64: String

  @Argument(help: "Client ID (UUID v4)")
  var clientID: String

  func run() throws {
    // Parse the base64 root key
    guard let rootKeyData = Data(base64Encoded: rootKeyBase64) else {
      throw ValidationError("Invalid base64 string for root key")
    }

    guard rootKeyData.count == 32 else {
      throw ValidationError(
        "Root key must be exactly 32 bytes, got \(rootKeyData.count) bytes"
      )
    }

    // Create the client chain
    let clientChain: ClientChain
    do {
      clientChain = try ClientChain(root: rootKeyData, clientID: clientID)
    } catch {
      throw ValidationError("Failed to create client chain: \(error.localizedDescription)")
    }

    // Generate the token
    let token: String
    do {
      token = try clientChain.token()
    } catch {
      throw ValidationError("Failed to generate token: \(error.localizedDescription)")
    }

    // Get the derived PASETO encryption key
    let pasetoKey: Data
    do {
      let key = try clientChain.tokenKey()
      pasetoKey = Data(key.material)
    } catch {
      throw ValidationError("Failed to derive PASETO key: \(error.localizedDescription)")
    }

    // Print the results
    print("Generated PASETO token:")
    print(token)
    print()
    print("Derived PASETO encryption key (base64):")
    print(pasetoKey.base64EncodedString())
  }
}
