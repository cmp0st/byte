# QR Code Device Setup

The Byte iOS app supports quick device configuration using QR codes. This eliminates the need to manually enter the server URL, device ID, and secret.

## How it Works

### Creating a Device with QR Code

When you create a new device using either CLI command, a QR code is automatically generated and displayed in the terminal:

```bash
# Using server CLI
byte server new-device

# OR using device CLI
byte device create
```

The QR code contains a JSON payload with:
- `serverUrl`: The HTTP server URL
- `deviceId`: The UUID of the device
- `secret`: The base64-encoded device secret

### Scanning the QR Code

1. Open the Byte iOS app
2. If not configured, you'll see the Setup screen
3. Tap "Scan QR Code" button
4. Point your camera at the QR code displayed in the terminal
5. The app will automatically fill in the server URL, device ID, and secret
6. Tap "Connect" to complete setup

## QR Code Format

The QR code contains a JSON string:

```json
{
  "serverUrl": "http://localhost:8080",
  "deviceId": "550e8400-e29b-41d4-a716-446655440000",
  "secret": "base64EncodedSecret=="
}
```

## Manual Setup

If you prefer or need to enter the configuration manually, you can still use the manual input fields in the Setup screen:

1. Enter Server URL (e.g., `http://localhost:8080`)
2. Enter Device ID (UUID v4 format)
3. Enter Secret (base64-encoded)
4. Tap "Connect"

## Permissions

The iOS app requires camera permissions to scan QR codes. On first use, iOS will prompt you to grant camera access. You can also enable it later in Settings > Privacy & Security > Camera > Byte.
