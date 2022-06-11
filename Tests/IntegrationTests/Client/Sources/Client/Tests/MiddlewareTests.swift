import Foundation

func testMiddlewares() async throws {
    var middlewareAPI = MiddlewareTestAPI(url: serverURL, bearerToken: "testToken")
    _ = try await middlewareAPI.testBearerToken()
    
    print("Testing middleware errors...")
    middlewareAPI = MiddlewareTestAPI(url: serverURL, bearerToken: "wrong token")
    do {
        _ = try await middlewareAPI.testBearerToken()
        fatalError("test() should have thrown an error")
    } catch {}
}
