import SwiftyBridges
import Vapor

struct BasicTestAPI: APIDefinition {
    /// This property contains the request sent by the client to call the API method.
    var req: Request
    
    public func testUnnamedStringParameter(_ string: String) -> String {
        string
    }
    
    public func testThrowingMethod() throws -> String {
        "Success"
    }
    
    public func testAsyncMethod() async -> String {
        "Success"
    }
    
    public func testAsyncThrowingMethod() async throws -> String {
        "Success"
    }
    
    public func testMultipleArguments(firstName: String, lastName: String) -> String {
        "Hello, \(firstName) \(lastName)!"
    }
}
