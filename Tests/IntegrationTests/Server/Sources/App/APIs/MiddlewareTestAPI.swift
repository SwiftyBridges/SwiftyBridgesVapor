import SwiftyBridges
import Vapor

struct MiddlewareTestAPI: APIDefinition {
    static var middlewares: [Middleware] = [
        TestMiddleware()
    ]
    
    var req: Request
    
    public func testBearerToken() -> String {
        "Success"
    }
}

private struct TestMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        guard request.headers.bearerAuthorization?.token == "testToken" else {
            throw Abort(.unauthorized)
        }
        
        return try await next.respond(to: request)
    }
}
