import Connect
import Crypto
import Foundation
import Paseto

/// Token expiration time matching the Go implementation
private let defaultTokenExpiration: TimeInterval = 30.0

/// Authentication interceptor for Connect-Swift that mimics the Go client interceptor
public final class AuthInterceptor: UnaryInterceptor {
  private let clientChain: ClientChain

  /// Initialize the authentication interceptor
  /// - Parameter clientChain: The client chain for key derivation
  public init(clientChain: ClientChain) {
    self.clientChain = clientChain
  }

  @available(*, unavailable, message: "Use AuthInterceptor.factory(clientChain:) instead")
  public convenience init(config: ProtocolClientConfig) {
    fatalError("Use AuthInterceptorFactory.create() instead")
  }

  @Sendable
  public func handleUnaryRequest<Message: ProtobufMessage>(
    _ request: HTTPRequest<Message>,
    proceed: @escaping @Sendable (Result<HTTPRequest<Message>, ConnectError>) -> Void
  ) {
    do {
      let token = try self.clientChain.token()

      // Add authentication headers
      var headers = request.headers
      headers["Authorization"] = ["Bearer \(token)"]
      headers["Device-ID"] = [self.clientChain.clientID]

      let modifiedRequest = HTTPRequest(
        url: request.url,
        headers: headers,
        message: request.message,
        method: request.method,
        trailers: request.trailers,
        idempotencyLevel: request.idempotencyLevel
      )

      proceed(.success(modifiedRequest))
    } catch {
      proceed(
        .failure(
          ConnectError(
            code: .unauthenticated,
            message:
              "Failed to create authentication token: \(error.localizedDescription)",
            exception: error,
            details: [],
            metadata: [:]
          )
        )
      )
    }
  }

  @Sendable
  public func handleUnaryResponse<Message: ProtobufMessage>(
    _ response: ResponseMessage<Message>,
    proceed: @escaping @Sendable (ResponseMessage<Message>) -> Void
  ) {
    // Pass through responses unchanged
    proceed(response)
  }

  /// Create an interceptor factory for use with Connect-Swift
  /// - Parameter clientChain: The client chain for authentication
  /// - Returns: An interceptor factory closure
  public static func factory(clientChain: ClientChain) -> InterceptorFactory {
    return InterceptorFactory { _ in
      AuthInterceptor(clientChain: clientChain)
    }
  }
}

/// PASETO payload structure for token creation
private struct PasetoPayload: Codable {
  let exp: TimeInterval  // Expiration time
  let iat: TimeInterval  // Issued at time
  let nbf: TimeInterval  // Not before time

  init(expiration: Date, issuedAt: Date, notBefore: Date) {
    self.exp = expiration.timeIntervalSince1970
    self.iat = issuedAt.timeIntervalSince1970
    self.nbf = notBefore.timeIntervalSince1970
  }
}
