// ConnectRPC API Client
import { createClient } from '@connectrpc/connect';
import { createConnectTransport } from '@connectrpc/connect-web';
import { FileService } from '../gen/files/v1/files_connect';

// Create transport for web (HTTP)
const transport = createConnectTransport({
  baseUrl: 'http://localhost:8080',
});

// Create client
export const fileServiceClient = createClient(FileService, transport);

// Re-export types for convenience
export * from '../gen/files/v1/files_pb';
