let client = ProtocolClient(
    httpClient: URLSessionHTTPClient(),
    config: ProtocolClientConfig(
        host: "https://demo.connectrpc.com",
        networkProtocol: .connect,
        codec: ProtoCodec(),
        interceptors: [InterceptorFactory { ExampleAuthInterceptor(config: $0) }]
    )
)
