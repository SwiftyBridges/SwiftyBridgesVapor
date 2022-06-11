import Foundation

let serverURL = URL(string: "http://127.0.0.1:8080/api")!

@main
struct Client {
    static func main() async throws {
        try await testBasicAPI()
        try await testGenerateClientStruct()
        try await testValidations()
        try await testMiddlewares()
        
        print("\nAll tests passed!!!")
    }
}
