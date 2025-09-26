#!/bin/bash

# Script to run integration tests against localhost:8080
# Usage: ./run-integration-test.sh CLIENT_ID CLIENT_SECRET

set -e

if [ $# -ne 2 ]; then
    echo "Usage: $0 CLIENT_ID CLIENT_SECRET"
    echo ""
    echo "Example:"
    echo "  $0 550e8400-e29b-41d4-a716-446655440000 dGVzdGtleWZvcmJ5dGVzZXJ2ZXJjbGllbnR0ZXN0"
    echo ""
    echo "Make sure your server is running on localhost:8080"
    exit 1
fi

CLIENT_ID="$1"
CLIENT_SECRET="$2"

echo "🚀 Running ByteClient integration tests..."
echo "📡 Server: http://localhost:8080"
echo "🆔 Client ID: $CLIENT_ID"
echo "🔐 Secret: ${CLIENT_SECRET:0:16}..."
echo ""

# Check if server is running
if ! curl -s --connect-timeout 2 http://localhost:8080 > /dev/null 2>&1; then
    echo "❌ Server not reachable at localhost:8080"
    echo "   Please start your server first"
    exit 1
fi

echo "✅ Server is reachable"
echo ""

# Export environment variables and run tests
export BYTE_CLIENT_ID="$CLIENT_ID"
export BYTE_CLIENT_SECRET="$CLIENT_SECRET"

# Run the integration tests
swift test --filter IntegrationTests --verbose

echo ""
echo "🎉 Integration tests completed!"