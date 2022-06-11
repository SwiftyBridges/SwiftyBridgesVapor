import Foundation

func testBasicAPI() async throws {
    let basicAPI = BasicTestAPI(url: serverURL)
    
    _ = try await basicAPI.testAsyncMethod()
    _ = try await basicAPI.testAsyncThrowingMethod()
    _ = try await basicAPI.testMultipleArguments(firstName: "First", lastName: "Last")
    _ = try await basicAPI.testThrowingMethod()
    _ = try await basicAPI.testUnnamedStringParameter("A string")
}
