import Connect
import Foundation

/// Main client class for the Byte file server, similar to the Go implementation
public class ByteClient {
    /// File service client
    public let files: Files_V1_FileServiceClientInterface

    /// Device service client
    public let devices: Devices_V1_DeviceServiceClientInterface

    private let configuration: ByteClientConfiguration
    private let clientChain: ClientChain

    /// Initialize a new Byte client
    /// - Parameter configuration: The client configuration
    /// - Throws: `ByteClientError` if initialization fails
    public init(configuration: ByteClientConfiguration) throws {
        // Validate configuration
        do {
            try configuration.validate()
        } catch let configError as ByteClientConfigurationError {
            throw ByteClientError.configurationError(configError)
        }

        self.configuration = configuration

        // Decode the secret key
        guard let rawKey = Data(base64Encoded: configuration.secret) else {
            throw ByteClientError.configurationError(.invalidSecret(configuration.secret))
        }

        // Create client chain for key derivation
        do {
            self.clientChain = try ClientChain(root: rawKey, clientID: configuration.deviceID)
        } catch let keyError as KeyError {
            throw ByteClientError.keyDerivationError(keyError.localizedDescription)
        }

        // Create Connect client with interceptors
        let connectClient = ProtocolClient(
            httpClient: URLSessionHTTPClient(),
            config: ProtocolClientConfig(
                host: configuration.serverURL,
                networkProtocol: .connect,
                codec: ProtoCodec(),
                interceptors: [AuthInterceptor.factory(clientChain: clientChain)]
            )
        )

        // Initialize service clients
        self.files = Files_V1_FileServiceClient(client: connectClient)
        self.devices = Devices_V1_DeviceServiceClient(client: connectClient)
    }

    /// Get the current configuration
    public var config: ByteClientConfiguration {
        return configuration
    }

    /// Get the client ID
    public var clientID: String {
        return clientChain.clientID
    }
}
