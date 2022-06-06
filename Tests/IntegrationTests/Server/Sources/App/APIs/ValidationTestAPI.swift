import Fluent
import SwiftyBridges
import Vapor

struct ValidationTestAPI: APIDefinition {
    var req: Request
    
    public func testValidatable(with info: NewUserInfo) throws {
        try info.validate() // Run the validations defined on `NewUserInfo`
    }
}

struct NewUserInfo: Codable, GenerateClientStruct, Validatable {
    /// The name of the user
    var name: String
    
    /// The email address of the new user
    var email: String
    
    /// The password for the new account
    var password: String
    
    static func validations(_ validations: inout Validations) {
        validations.add("name", as: String.self, is: !.empty)
        validations.add("email", as: String.self, is: .email)
        validations.add("password", as: String.self, is: .count(8...))
    }
}
