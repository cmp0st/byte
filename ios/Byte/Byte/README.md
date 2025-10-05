# Byte Client iOS App

A SwiftUI application for interacting with the Byte file server using the ByteClient library.

## Features

- **Secure Configuration**: Stores server URL, device ID, and secret in the iOS Keychain
- **Device Management**: List, create, and delete devices through the API
- **File Management**: Upload, download, list, and delete files
- **User-Friendly Setup**: Guided setup process for new users

## Architecture

### Core Components

1. **AppState**: Main app state manager that handles configuration and client initialization
2. **KeychainHelper**: Secure storage for sensitive configuration data
3. **SetupView**: Initial configuration screen for new users
4. **MainTabView**: Main interface with tabs for Devices, Files, and Settings

### Views

- **SetupView**: Configuration form with server URL, device ID, and secret fields
- **DevicesView**: Device management interface with full API integration
- **FilesView**: File management interface with full API integration
- **SettingsView**: App settings and configuration management

### Security

- Server URL and Device ID are stored in Keychain for convenience
- Secret key is securely stored in iOS Keychain using the Security framework
- Device ID is automatically generated as UUID v4 when needed

## Current Status

### ✅ Completed
- Core app structure and navigation
- Keychain integration for secure storage
- Configuration validation
- UI for setup, devices, files, and settings
- Error handling and loading states
- **Full API Integration**: All device and file operations now use real ByteClient API calls
- **Proper Generated Types**: Uses `Devices_V1_Device`, `Files_V1_FileInfo`, and all request/response types

### API Integration

#### Device Operations
- **List Devices**: `client.devices.listDevices()` with `Devices_V1_ListDevicesRequest`
- **Create Device**: `client.devices.createDevice()` with `Devices_V1_CreateDeviceRequest`
- **Delete Device**: `client.devices.deleteDevice()` with `Devices_V1_DeleteDeviceRequest`

#### File Operations
- **List Files**: `client.files.listFiles()` with `Files_V1_ListFilesRequest`
- **Upload File**: `client.files.uploadFile()` with `Files_V1_UploadFileRequest`
- **Download File**: `client.files.downloadFile()` with `Files_V1_DownloadFileRequest`
- **Delete File**: `client.files.deleteFile()` with `Files_V1_DeleteFileRequest`

### Required Dependencies

The app expects these dependencies to be properly configured in your project:
1. **Generated Module**: Contains protobuf-generated types (should be generated from your .proto files)
2. **Connect Framework**: For the Connect protocol client
3. **Crypto and Paseto**: For authentication token generation

## Usage

### First-time Setup
1. Launch the app
2. Enter your server URL (e.g., `https://your-server.com`)
3. Generate or enter a device ID (UUID v4 format)
4. Enter your base64-encoded secret key
5. Tap "Connect" to save configuration and initialize the client

### Device Management
- View all registered devices with their details
- Create new devices by name
- Delete existing devices
- Refresh device list from server

### File Management
- View all files with name and size information
- Upload new files (currently text-based, easily extensible)
- Download files from server
- Delete files
- Refresh file list from server

### Settings
- View current configuration including server URL, device ID, and client ID
- Reset configuration (clears keychain and returns to setup)

## File Structure

```
/repo/
├── ByteApp.swift              # Main app entry point
├── ContentView.swift          # Root content view
├── AppState.swift             # Main app state manager
├── KeychainHelper.swift       # Keychain operations
├── SetupView.swift           # Initial setup interface
├── MainTabView.swift         # Main tabbed interface
├── DevicesView.swift         # Device management UI (full API integration)
├── FilesView.swift           # File management UI (full API integration)
├── ByteClient.swift          # Main client class
├── Configuration.swift       # Client configuration types
├── Errors.swift              # Error definitions
└── AuthInterceptor.swift     # Authentication interceptor
```

## Build Requirements

To build successfully, ensure:

1. **Generated Module**: Your protobuf files are properly compiled to Swift
2. **Connect-Swift**: Added as a dependency with proper client interfaces
3. **Crypto Libraries**: Required for PASETO token generation in AuthInterceptor

The app uses the real ByteClient API throughout - no mock implementations remain.