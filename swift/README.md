# ByteClient Swift

A Swift client library for the Byte file server, providing secure file operations and device management.

## Features

- **File Operations**: List directories, create directories
- **Device Management**: Create, list, and delete devices
- **Secure Authentication**: PASETO-based token authentication with automatic key derivation
- **iOS/macOS Support**: Compatible with iOS 15+ and macOS 12+

## Installation

### Swift Package Manager

Add this to your `Package.swift`:

```swift
dependencies: [
    .package(path: "./swift")
]
```

Or add it to your Xcode project via File → Add Package Dependencies.

## Usage

### Basic Setup

```swift
import ByteClient

// Configure the client
let config = ByteClientConfiguration(
    serverURL: "https://your-server.com",
    deviceID: "your-uuid-v4-device-id",
    secret: "your-base64-encoded-secret"
)

// Create the client
let client = try ByteClient(configuration: config)
```

### File Operations

```swift
// List directory contents
let response = await client.files.listDirectory(
    request: Files_V1_ListDirectoryRequest.with { req in
        req.path = "/some/path"
    },
    headers: [:]
)

// Create a directory
let response = await client.files.makeDirectory(
    request: Files_V1_MakeDirectoryRequest.with { req in
        req.path = "/new/directory"
    },
    headers: [:]
)
```

### Device Management

```swift
// Create a new device
let response = await client.devices.createDevice(
    request: Devices_V1_CreateDeviceRequest.with { req in
        req.name = "My Device"
    },
    headers: [:]
)

// List all devices
let response = await client.devices.listDevices(
    request: Devices_V1_ListDevicesRequest(),
    headers: [:]
)
```

## Architecture

The client is structured similarly to the Go client:

- **ByteClient**: Main client class with file and device service clients
- **ClientChain**: Key derivation and cryptographic operations
- **AuthInterceptor**: Automatic authentication header injection
- **Configuration**: Type-safe client configuration

## Security

- Uses PASETO v4 tokens for authentication
- Implements HKDF for secure key derivation
- AES-GCM encryption for sensitive data
- Short-lived tokens (30-second expiration) to minimize replay attack risk

## Dependencies

- [Connect-Swift](https://github.com/connectrpc/connect-swift): gRPC-Web client
- [SwiftProtobuf](https://github.com/apple/swift-protobuf): Protocol buffer support
- [Swift-Crypto](https://github.com/apple/swift-crypto): Cryptographic operations
- [Swift-PASETO](https://github.com/aidantwoods/swift-paseto): PASETO token implementation