//
//  User.swift
//  User
//
//  Created by Stephen Kockentiedt on 14.09.21.
//

import Fluent
import Vapor

final class User: Model, Content {
    static let schema = "users"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String
    
    @Field(key: "email")
    var email: String

    @Field(key: "password_hash")
    var passwordHash: String

    init() { }
    
    init(id: UUID? = nil, name: String, email: String, passwordHash: String) {
        self.id = id
        self.name = name
        self.email = email
        self.passwordHash = passwordHash
    }
}

extension User: ModelAuthenticatable {
    static let usernameKey = \User.$email
    static let passwordHashKey = \User.$passwordHash
    
    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.passwordHash)
    }
}

extension User {
    func generateToken() throws -> UserToken {
        try .init(
            value: [UInt8].random(count: 16).base64,
            userID: self.requireID()
        )
    }
}

extension ModelAuthenticatable {
    private var _$username: Field<String> {
        self[keyPath: Self.usernameKey]
    }

    private var _$passwordHash: Field<String> {
        self[keyPath: Self.passwordHashKey]
    }
    
    /// Tries to authenticate the user and throws if this fails.
    ///
    /// This method tries to find the user with the given username in the database, then checks the password using `verify(password:)`. If this fails, an error is thrown. If it succeeds, the user is logged in to `reqest.auth` and is returned.
    /// - Parameters:
    ///   - username: The username of the user to be authenticated. This uses the field referenced by `usernameKey` from `ModelAuthenticatable`.
    ///   - password: The password to be verified. This uses the field referenced by `passwordHashKey` from `ModelAuthenticatable`.
    ///   - request: The request the authentication is part of
    ///   - database: An optional database ID to be used. If it is not specified, the default request database is used.
    /// - Returns: The authenticated user.
    /// - Throws: `Abort(.unauthorized)` if the authentication fails or any errors from `verify(password:)` or the database query.
    @discardableResult
    public static func authenticate(username: String, password: String, for request: Request, database: DatabaseID? = nil) async throws -> Self {
        let user = try await Self.query(on: request.db(database))
            .filter(\._$username == username)
            .first()
        guard
            let user = user,
            try user.verify(password: password)
        else {
            throw Abort(.unauthorized)
        }
        request.auth.login(user)
        return user
    }
}
