//
//  UserToken.swift
//  UserToken
//
//  Created by Stephen Kockentiedt on 14.09.21.
//

import Fluent
import Vapor

final class UserToken: Model, Content {
    static let schema = "user_tokens"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "value")
    var value: String
    
    @Field(key: "expiration_date")
    var expirationDate: Date

    @Parent(key: "user_id")
    var user: User

    init() { }

    init(id: UUID? = nil, value: String, userID: User.IDValue) {
        self.id = id
        self.value = value
        self.expirationDate = Date().addingTimeInterval(30*24*60*60)
        self.$user.id = userID
    }
}

extension UserToken: ModelTokenAuthenticatable {
    static let valueKey = \UserToken.$value
    static let userKey = \UserToken.$user

    var isValid: Bool {
        Date() < expirationDate
    }
}
