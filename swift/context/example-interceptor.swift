import Connect

/// Interceptor that asynchronously fetches an auth token and then adds an `Authorization`
/// header to outbound requests to `demo.connectrpc.com`. If the token fetch fails, it rejects
/// the outbound request and returns an error to the original caller.
final class ExampleAuthInterceptor: UnaryInterceptor {
    init(config: ProtocolClientConfig) { /* Optional setup */  }

    @Sendable
    func handleUnaryRequest<Message: ProtobufMessage>(
        _ request: HTTPRequest<Message>,
        proceed: @escaping @Sendable (Result<HTTPRequest<Message>, ConnectError>) -> Void
    ) {
        guard request.url.host == "demo.connectrpc.com" else {
            // Allow the request to be sent as-is.
            proceed(.success(request))
            return
        }

        fetchUserToken(forPath: request.url.path) { token in
            if let token = token {
                // Alter the request's headers and pass the request on to other interceptors
                // before eventually sending it to the server.
                var headers = request.headers
                headers["Authorization"] = ["Bearer \(token)"]
                proceed(
                    .success(
                        HTTPRequest(
                            url: request.url,
                            headers: headers,
                            message: request.message,
                            trailers: request.trailers
                        )))
            } else {
                // No valid token was available - reject the request and return
                // an error to the caller.
                proceed(
                    .failure(
                        ConnectError(
                            code: .unknown, message: "auth token fetch failed",
                            exception: nil, details: [], metadata: [:]
                        )))
            }
        }
    }

    @Sendable
    func handleUnaryResponse<Message: ProtobufMessage>(
        _ response: ResponseMessage<Message>,
        proceed: @escaping @Sendable (ResponseMessage<Message>) -> Void
    ) {
        // Can be used to observe/alter the response.
        proceed(response)
    }
}
