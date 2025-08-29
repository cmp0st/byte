// ConnectRPC API Client
import { createClient } from '@connectrpc/connect';
import { createConnectTransport } from '@connectrpc/connect-web';
import { FileService } from '../gen/files/v1/files_connect';
import { 
  ListDirectoryRequest,
  ReadFileRequest,
  WriteFileRequest,
  CreateDirectoryRequest,
  DeletePathRequest,
  MovePathRequest,
  GetPathInfoRequest,
} from '../gen/files/v1/files_pb';

// Create transport for web (HTTP)
const transport = createConnectTransport({
  baseUrl: 'http://192.168.8.143:8080',
});

// Create client
const client = createClient(FileService, transport);

// Extended API client with helper methods
export const fileServiceClient = {
  // Directory operations
  async listDirectory(path: string) {
    const request = new ListDirectoryRequest({ path });
    return await client.listDirectory(request);
  },

  async createDirectory(path: string, name: string) {
    const fullPath = path === '/' ? `/${name}` : `${path}/${name}`;
    const request = new CreateDirectoryRequest({ path: fullPath });
    return await client.createDirectory(request);
  },

  // File operations
  async readFile(path: string): Promise<string> {
    const request = new ReadFileRequest({ path });
    const stream = client.readFile(request);
    
    const chunks: Uint8Array[] = [];
    for await (const response of stream) {
      if (response.chunk) {
        chunks.push(response.chunk);
      }
    }
    
    // Combine all chunks into a single Uint8Array
    const totalLength = chunks.reduce((sum, chunk) => sum + chunk.length, 0);
    const combined = new Uint8Array(totalLength);
    let offset = 0;
    for (const chunk of chunks) {
      combined.set(chunk, offset);
      offset += chunk.length;
    }
    
    // Convert to string (assuming UTF-8 text file)
    return new TextDecoder().decode(combined);
  },

  async writeFile(path: string, content: string) {
    const stream = client.writeFile();
    
    // Convert string to Uint8Array
    const encoder = new TextEncoder();
    const data = encoder.encode(content);
    
    // Send the file data
    await stream.send(new WriteFileRequest({
      path,
      chunk: data,
    }));
    
    // Close and get response
    const response = await stream.close();
    return response;
  },

  async createFile(path: string, name: string, content: string = '') {
    const fullPath = path === '/' ? `/${name}` : `${path}/${name}`;
    return await this.writeFile(fullPath, content);
  },

  // Delete operations
  async deletePath(path: string, recursive: boolean = false) {
    const request = new DeletePathRequest({ path, recursive });
    return await client.deletePath(request);
  },

  // Move/rename operations
  async movePath(sourcePath: string, destinationPath: string) {
    const request = new MovePathRequest({ 
      sourcePath, 
      destinationPath 
    });
    return await client.movePath(request);
  },

  async renamePath(path: string, newName: string) {
    const pathParts = path.split('/');
    pathParts[pathParts.length - 1] = newName;
    const newPath = pathParts.join('/');
    return await this.movePath(path, newPath);
  },

  // Info operations
  async getPathInfo(path: string) {
    const request = new GetPathInfoRequest({ path });
    return await client.getPathInfo(request);
  },

  // Utility methods
  isTextFile(filename: string): boolean {
    const textExtensions = [
      '.txt', '.md', '.json', '.js', '.jsx', '.ts', '.tsx',
      '.html', '.css', '.scss', '.less', '.xml', '.yaml', '.yml',
      '.py', '.java', '.c', '.cpp', '.h', '.hpp', '.cs', '.php',
      '.rb', '.go', '.rs', '.kt', '.swift', '.sh', '.bash',
      '.sql', '.csv', '.log', '.conf', '.config', '.ini',
    ];
    
    const extension = filename.toLowerCase().substring(filename.lastIndexOf('.'));
    return textExtensions.includes(extension) || !extension.includes('.');
  },
};

// Re-export types for convenience
export * from '../gen/files/v1/files_pb';
