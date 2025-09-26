# Integration Testing

This guide shows how to run end-to-end tests against your running Byte server.

## Prerequisites

1. **Server Running**: Start your Byte server on `localhost:8080`
2. **Valid Credentials**: You need a valid client ID (UUID v4) and base64-encoded secret

## Quick Test

Use the provided script:

```bash
./run-integration-test.sh CLIENT_ID CLIENT_SECRET
```

**Example:**
```bash
./run-integration-test.sh 550e8400-e29b-41d4-a716-446655440000 dGVzdGtleWZvcmJ5dGVzZXJ2ZXJjbGllbnR0ZXN0
```

## Manual Test

Alternatively, set environment variables and run tests directly:

```bash
export BYTE_CLIENT_ID="your-uuid-v4-client-id"
export BYTE_CLIENT_SECRET="your-base64-encoded-secret"
swift test --filter IntegrationTests --verbose
```

## What Gets Tested

The integration tests verify:

1. **Authentication**: PASETO token generation and validation
2. **File Operations**:
   - List root directory (`/`)
   - Create new directories
   - Verify directory creation
3. **Device Operations**:
   - List devices
   - Display device information
4. **Network Communication**:
   - gRPC-Web connectivity
   - Request/response handling
   - Error handling

## Expected Output

Successful tests will show:
```
✅ Server is reachable

🔧 Testing connection to server...
✅ Successfully listed root directory!
📁 Found 3 entries:
   📂 documents (0 bytes)
   📄 readme.txt (1234 bytes)
   📂 uploads (0 bytes)

🔧 Testing directory creation...
✅ Successfully created directory: /test-swift-client-abc123
✅ Directory appears in listing!

🔧 Testing device operations...
✅ Successfully listed devices!
📱 Found 2 devices:
   • My Device (ID: 550e8400...)
   • Test Device (ID: 7f3d2e1a...)

🔧 Testing authentication...
✅ Authentication successful!

✅ Client configuration and initialization successful!

🎉 Integration tests completed!
```

## Troubleshooting

**Server not reachable:**
- Ensure server is running on `localhost:8080`
- Check server logs for startup issues

**Authentication errors:**
- Verify client ID is a valid UUID v4
- Ensure secret is properly base64 encoded
- Check that the client ID exists in your server's database

**Connection errors:**
- Verify server supports gRPC-Web protocol
- Check firewall settings
- Ensure server is configured for the correct host/port