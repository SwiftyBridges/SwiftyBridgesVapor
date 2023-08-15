import XCTest
import SwiftSyntaxMacrosTestSupport
@testable import BridgeBuilder

final class BridgeBuilderTests: XCTestCase {
    func testCodeGeneration() throws {
        let source =
        ####"""
        import Fluent
        import SwiftyBridges
        import SwiftyBridgesFluent
        import Vapor

        struct GenerateClientStructTestAPI: APIDefinition {
            var req: Request
            
            public func testSimpleStruct(_ name: Name) -> Name {
                name
            }
            
            public func testPerson(_ person: Person) -> Person {
                person
            }
            
            public func testPerson(_ person: Person, dogs: [Dog], youngerSiblings: [Person]) -> Person {
                person.$dogs.value = dogs
                person.$youngerSiblings.value = youngerSiblings
                return person
            }
            
            public func testDog(_ dog: Dog) -> Dog {
                dog
            }
            
            public func testDog(_ dog: Dog, owner: Person, sitter: Person?, bestCatFriend: Cat?) -> Dog {
                dog.$owner.value = owner
                dog.$sitter.value = sitter
                dog.$bestCatFriend.value  = bestCatFriend
                return dog
            }
            
            public func testCat(_ cat: Cat) -> Cat {
                cat
            }
            
            public func testCat(_ cat: Cat, bestDogFriend: Dog) -> Cat {
                cat.$bestDogFriend.value = bestDogFriend
                return cat
            }

            public func testModelWithHiddenProperties(_ model: ModelWithHiddenProperties) async throws -> ModelWithHiddenProperties {
                model.hiddenBoolean = true
                model.hiddenEnum = .hiddenCase
                model.hiddenField = "A hidden field"
                model.hiddenGroup = HiddenGroup(fieldInGroup: "A hidden field in a group")
                let parent = HiddenParent()
                try await parent.save(on: req.db)
                model.$hiddenParent.id = try parent.requireID()
                try await model.save(on: req.db)
                return model
            }
        }

        /// If a type conforms to `GenerateClientStruct`, SwiftyBridges will generate a `Codable` struct for the client with the same name and properties. If the type has no custom `Codable` logic and uses no property wrappers, this type can be used as a parameter or result type of an `APIClient`. Ensure that all property types are also available to the client. `GenerateClientStruct`can also be used with Fluent models.
        struct Name: Codable, GenerateClientStruct {
            var firstName: String
            var middleName = ""
            var lastName: String
        }

        final class Person: Model, Content, GenerateClientStruct, GenerateEquatable {
            static let schema = "persons"

            @ID(key: .id)
            var id: UUID?

            @Field(key: "name")
            var name: String
            
            @Children(for: \.$owner)
            var dogs: [Dog]
            
            @Siblings(through: SiblingPivot.self, from: \.$olderSibling, to: \.$youngerSibling)
            var youngerSiblings: [Person]

            init() { }
            
            init(id: UUID? = nil, name: String) {
                self.id = id
                self.name = name
            }
        }

        final class Dog: Model, Content, GenerateClientStruct, GenerateHashable {
            static let schema = "dogs"

            @ID(key: .id)
            var id: UUID?

            @Field(key: "name")
            var name: String
            
            @Parent(key: "owner_id")
            var owner: Person
            
            @OptionalParent(key: "dog_sitter_id")
            var sitter: Person?
            
            @OptionalParent(key: "best_cat_friend_id")
            var bestCatFriend: Cat?

            init() { }
            
            init(id: UUID? = nil, name: String, ownerID: Person.IDValue) {
                self.id = id
                self.name = name
                self.$owner.id = ownerID
            }
            
            init(id: UUID? = nil, name: String, owner: Person) {
                self.id = id
                self.name = name
                self.$owner.value = owner
            }
        }

        final class Cat: Model, Content, GenerateClientStruct, GenerateEquatable {
            static let schema = "cats"
            
            @ID(key: .id)
            var id: UUID?

            @Field(key: "name")
            var name: String
            
            @OptionalChild(for: \.$bestCatFriend)
            var bestDogFriend: Optional<Dog>
            
            init() { }
        }

        final class SiblingPivot: Model {
            static let schema = "friendships"

                @ID(key: .id)
                var id: UUID?

                @Parent(key: "older_sibling_id")
                var olderSibling: Person

                @Parent(key: "younger_sibling_id")
                var youngerSibling: Person

                init() { }

                init(id: UUID? = nil, olderSibling: Person, youngerSibling: Person) throws {
                    self.id = id
                    self.$olderSibling.id = try olderSibling.requireID()
                    self.$youngerSibling.id = try youngerSibling.requireID()
                }
        }

        final class ModelWithHiddenProperties: Model, Content, GenerateClientStruct, GenerateEquatable {
            static let schema = "models_with_hidden_properties"
            
            @ID
            var id: UUID?
            
            @Field(key: "name")
            var name: String

            @HiddenFromClient(Boolean(key: "hidden_boolean"))
            var hiddenBoolean: Bool

            @HiddenFromClient(Children(for: \.$parent))
            var hiddenChildren: [HiddenChild]

            @HiddenFromClient(Enum(key: "hidden_enum"))
            var hiddenEnum: HiddenEnum
            
            @HiddenFromClient(Field(key: "hidden_field"))
            var hiddenField: String

            @HiddenFromClient(Group(key: "hidden_group"))
            var hiddenGroup: HiddenGroup

            @HiddenFromClient(OptionalBoolean(key: "hidden_boolean2"))
            var hiddenBoolean2: Bool?

            @HiddenFromClient(OptionalChild(for: \.$parent))
            var hiddenChild: HiddenChild?

            @HiddenFromClient(OptionalEnum(key: "hidden_optional_enum"))
            var hiddenOptionalEnum: HiddenEnum?
            
            @HiddenFromClient(OptionalField(key: "hidden_optional_field"))
            var hiddenOptionalField: String?
            
            @HiddenFromClient(OptionalParent(key: "hidden_optional_parent"))
            var hiddenOptionalParent: HiddenParent?
            
            @HiddenFromClient(Parent(key: "hidden_parent"))
            var hiddenParent: HiddenParent

            @HiddenFromClient(Siblings(through: Pivot.self, from: \.$source, to: \.$target))
            var hiddenSiblings: [HiddenSibling]

            @HiddenFromClient(Timestamp(key: "hidden_timestamp", on: .create))
            var hiddenTimestamp: Date?
            
            init() { }
            
            init(id: UUID? = nil, name: String, hiddenField: String) {
                self.id = id
                self.name = name
                self.hiddenField = hiddenField
            }
        }

        final class HiddenChild: Model {
            static let schema = "hidden_children"

            @ID
            var id: UUID?

            @Parent(key: "parent_id")
            var parent: ModelWithHiddenProperties
            
            init() { }
        }

        enum HiddenEnum: String, Codable {
            case hiddenCase
        }

        final class HiddenGroup: Fields {
            @Field(key: "field_in_group")
            var fieldInGroup: String

            init() {}

            init(fieldInGroup: String) {
                self.fieldInGroup = fieldInGroup
            }
        }

        final class HiddenParent: Model {
            static let schema = "hidden_parents"

            @ID
            var id: UUID?
            
            init() { }
        }

        final class Pivot: Model {
            static let schema = "pivots"

            @ID
            var id: UUID?

            @Parent(key: "source_id")
            var source: ModelWithHiddenProperties

            @Parent(key: "target_id")
            var target: HiddenSibling
            
            init() { }
        }

        final class HiddenSibling: Model {
            static let schema = "hidden_siblings"

            @ID
            var id: UUID?
            
            init() { }
        }

        struct GenerateClientStructTestStruct: SwiftyBridges.GenerateClientStruct {}
        struct GenerateEquatableTestStruct: SwiftyBridges.GenerateClientStruct, SwiftyBridges.GenerateEquatable {}
        struct GenerateHashableTestStruct: SwiftyBridges.GenerateClientStruct, SwiftyBridges.GenerateHashable {}
        class GenerateClientStructTestClass: SwiftyBridges.GenerateClientStruct {}
        class GenerateEquatableTestClass: SwiftyBridges.GenerateClientStruct, SwiftyBridges.GenerateEquatable {}
        class GenerateHashableTestClass: SwiftyBridges.GenerateClientStruct, SwiftyBridges.GenerateHashable {}

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
        
        // bridge: copyToClient
        enum CopyToClientEnum: Codable {
            case firstCase
            case secondCase
        }

        // bridge: copyToClient
        /// This type even has a documentation comment!
        ///
        /// A long one!
        struct CopyToClientStruct: Codable {
            var storedProperty: Int
            
            var computedProperty: Int {
                storedProperty + 1
            }
        }

        // Text before annotation
        //bridge:copyToClient
        // Text after annotation
        class CopyToClientClass: Codable {
            var storedProperty: Int
            
            init(storedProperty: Int) {
                self.storedProperty = storedProperty
            }
            
            var computedProperty: Int {
                storedProperty + 1
            }
        }

        //bridge: copyToClient
        extension CopyToClientStruct {
            func methodInExtension() -> Int {
                storedProperty
            }
        }
        
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
        """####
        
        let expectedServerSource =
        ####"""
        // Generated by SwiftyBridges. DO NOT MODIFY!

        import SwiftyBridges
        import Vapor
        #if canImport(Fluent)
            import Fluent
        #endif
        #if canImport(SwiftyBridgesFluent)
            import SwiftyBridgesFluent
        #endif

        #warning(
        ###"""
        A test warning
        """###
        )

        #warning(
        ###"""
        Another test warning
        """###
        )

        private func checkIfAllAPITypesAreCodable() {
            #sourceLocation (file: "", line: 1)
            #sourceLocation (file: "/test.swift", line: 9)
            let _: APITypesMustBeCodable<Name>
            #sourceLocation (file: "/test.swift", line: 9)
            let _: APITypesMustBeCodable<Name>
            #sourceLocation (file: "/test.swift", line: 13)
            let _: APITypesMustBeCodable<Person>
            #sourceLocation (file: "/test.swift", line: 13)
            let _: APITypesMustBeCodable<Person>
            #sourceLocation (file: "/test.swift", line: 17)
            let _: APITypesMustBeCodable<Person>
            #sourceLocation (file: "/test.swift", line: 17)
            let _: APITypesMustBeCodable<[Dog]>
            #sourceLocation (file: "/test.swift", line: 17)
            let _: APITypesMustBeCodable<[Person]>
            #sourceLocation (file: "/test.swift", line: 17)
            let _: APITypesMustBeCodable<Person>
            #sourceLocation (file: "/test.swift", line: 23)
            let _: APITypesMustBeCodable<Dog>
            #sourceLocation (file: "/test.swift", line: 23)
            let _: APITypesMustBeCodable<Dog>
            #sourceLocation (file: "/test.swift", line: 27)
            let _: APITypesMustBeCodable<Dog>
            #sourceLocation (file: "/test.swift", line: 27)
            let _: APITypesMustBeCodable<Person>
            #sourceLocation (file: "/test.swift", line: 27)
            let _: APITypesMustBeCodable<Person?>
            #sourceLocation (file: "/test.swift", line: 27)
            let _: APITypesMustBeCodable<Cat?>
            #sourceLocation (file: "/test.swift", line: 27)
            let _: APITypesMustBeCodable<Dog>
            #sourceLocation (file: "/test.swift", line: 34)
            let _: APITypesMustBeCodable<Cat>
            #sourceLocation (file: "/test.swift", line: 34)
            let _: APITypesMustBeCodable<Cat>
            #sourceLocation (file: "/test.swift", line: 38)
            let _: APITypesMustBeCodable<Cat>
            #sourceLocation (file: "/test.swift", line: 38)
            let _: APITypesMustBeCodable<Dog>
            #sourceLocation (file: "/test.swift", line: 38)
            let _: APITypesMustBeCodable<Cat>
            #sourceLocation (file: "/test.swift", line: 43)
            let _: APITypesMustBeCodable<ModelWithHiddenProperties>
            #sourceLocation (file: "/test.swift", line: 43)
            let _: APITypesMustBeCodable<ModelWithHiddenProperties>
            #sourceLocation (file: "/test.swift", line: 283)
            let _: APITypesMustBeCodable<String>
            #sourceLocation (file: "/test.swift", line: 283)
            let _: APITypesMustBeCodable<String>
            #sourceLocation (file: "/test.swift", line: 287)
            let _: APITypesMustBeCodable<String>
            #sourceLocation (file: "/test.swift", line: 291)
            let _: APITypesMustBeCodable<String>
            #sourceLocation (file: "/test.swift", line: 295)
            let _: APITypesMustBeCodable<String>
            #sourceLocation (file: "/test.swift", line: 299)
            let _: APITypesMustBeCodable<String>
            #sourceLocation (file: "/test.swift", line: 299)
            let _: APITypesMustBeCodable<String>
            #sourceLocation (file: "/test.swift", line: 299)
            let _: APITypesMustBeCodable<String>
            #sourceLocation (file: "/test.swift", line: 311)
            let _: APITypesMustBeCodable<String>
            #sourceLocation (file: "/test.swift", line: 329)
            let _: APITypesMustBeCodable<NewUserInfo>
            #sourceLocation (file: "/test.swift", line: 329)
            let _: APITypesMustBeCodable<NoReturnValue>
            #sourceLocation ()
        }

        extension GenerateClientStructTestAPI {
            static let remotelyCallableMethods: [AnyAPIMethod<GenerateClientStructTestAPI>] = [
                AnyAPIMethod(method: Call_testSimpleStruct__Name.self),
                AnyAPIMethod(method: Call_testPerson__Person.self),
                AnyAPIMethod(method: Call_testPerson__Person_dogs__Dog__youngerSiblings__Person_.self),
                AnyAPIMethod(method: Call_testDog__Dog.self),
                AnyAPIMethod(method: Call_testDog__Dog_owner_Person_sitter_Person__bestCatFriend_Cat_.self),
                AnyAPIMethod(method: Call_testCat__Cat.self),
                AnyAPIMethod(method: Call_testCat__Cat_bestDogFriend_Dog.self),
                AnyAPIMethod(method: Call_testModelWithHiddenProperties__ModelWithHiddenProperties.self)
            ]

            private struct Call_testSimpleStruct__Name: APIMethodCall {
                typealias API = GenerateClientStructTestAPI
                typealias ReturnType = Name
                static let methodID: APIMethodID = "testSimpleStruct(_: Name) -> Name"
                var parameter0: Name

                enum CodingKeys: String, CodingKey {
                    case parameter0 = "0"
                }

                func call(on api: API) async throws -> Name {
                    api.testSimpleStruct(
                        parameter0
                    )
                }
            }

            private struct Call_testPerson__Person: APIMethodCall {
                typealias API = GenerateClientStructTestAPI
                typealias ReturnType = Person
                static let methodID: APIMethodID = "testPerson(_: Person) -> Person"
                var parameter0: Person

                enum CodingKeys: String, CodingKey {
                    case parameter0 = "0"
                }

                func call(on api: API) async throws -> Person {
                    api.testPerson(
                        parameter0
                    )
                }
            }

            private struct Call_testPerson__Person_dogs__Dog__youngerSiblings__Person_: APIMethodCall {
                typealias API = GenerateClientStructTestAPI
                typealias ReturnType = Person
                static let methodID: APIMethodID = "testPerson(_: Person, dogs: [Dog], youngerSiblings: [Person]) -> Person"
                var parameter0: Person
                var parameter1: [Dog]
                var parameter2: [Person]

                enum CodingKeys: String, CodingKey {
                    case parameter0 = "0"
                    case parameter1 = "1_dogs"
                    case parameter2 = "2_youngerSiblings"
                }

                func call(on api: API) async throws -> Person {
                    api.testPerson(
                        parameter0,
                        dogs: parameter1,
                        youngerSiblings: parameter2
                    )
                }
            }

            private struct Call_testDog__Dog: APIMethodCall {
                typealias API = GenerateClientStructTestAPI
                typealias ReturnType = Dog
                static let methodID: APIMethodID = "testDog(_: Dog) -> Dog"
                var parameter0: Dog

                enum CodingKeys: String, CodingKey {
                    case parameter0 = "0"
                }

                func call(on api: API) async throws -> Dog {
                    api.testDog(
                        parameter0
                    )
                }
            }

            private struct Call_testDog__Dog_owner_Person_sitter_Person__bestCatFriend_Cat_: APIMethodCall {
                typealias API = GenerateClientStructTestAPI
                typealias ReturnType = Dog
                static let methodID: APIMethodID = "testDog(_: Dog, owner: Person, sitter: Person?, bestCatFriend: Cat?) -> Dog"
                var parameter0: Dog
                var parameter1: Person
                var parameter2: Person?
                var parameter3: Cat?

                enum CodingKeys: String, CodingKey {
                    case parameter0 = "0"
                    case parameter1 = "1_owner"
                    case parameter2 = "2_sitter"
                    case parameter3 = "3_bestCatFriend"
                }

                func call(on api: API) async throws -> Dog {
                    api.testDog(
                        parameter0,
                        owner: parameter1,
                        sitter: parameter2,
                        bestCatFriend: parameter3
                    )
                }
            }

            private struct Call_testCat__Cat: APIMethodCall {
                typealias API = GenerateClientStructTestAPI
                typealias ReturnType = Cat
                static let methodID: APIMethodID = "testCat(_: Cat) -> Cat"
                var parameter0: Cat

                enum CodingKeys: String, CodingKey {
                    case parameter0 = "0"
                }

                func call(on api: API) async throws -> Cat {
                    api.testCat(
                        parameter0
                    )
                }
            }

            private struct Call_testCat__Cat_bestDogFriend_Dog: APIMethodCall {
                typealias API = GenerateClientStructTestAPI
                typealias ReturnType = Cat
                static let methodID: APIMethodID = "testCat(_: Cat, bestDogFriend: Dog) -> Cat"
                var parameter0: Cat
                var parameter1: Dog

                enum CodingKeys: String, CodingKey {
                    case parameter0 = "0"
                    case parameter1 = "1_bestDogFriend"
                }

                func call(on api: API) async throws -> Cat {
                    api.testCat(
                        parameter0,
                        bestDogFriend: parameter1
                    )
                }
            }

            private struct Call_testModelWithHiddenProperties__ModelWithHiddenProperties: APIMethodCall {
                typealias API = GenerateClientStructTestAPI
                typealias ReturnType = ModelWithHiddenProperties
                static let methodID: APIMethodID = "testModelWithHiddenProperties(_: ModelWithHiddenProperties) -> ModelWithHiddenProperties"
                var parameter0: ModelWithHiddenProperties

                enum CodingKeys: String, CodingKey {
                    case parameter0 = "0"
                }

                func call(on api: API) async throws -> ModelWithHiddenProperties {
                    try await api.testModelWithHiddenProperties(
                        parameter0
                    )
                }
            }
        }
        
        extension BasicTestAPI {
            static let remotelyCallableMethods: [AnyAPIMethod<BasicTestAPI>] = [
                AnyAPIMethod(method: Call_testUnnamedStringParameter__String.self),
                AnyAPIMethod(method: Call_testThrowingMethod.self),
                AnyAPIMethod(method: Call_testAsyncMethod.self),
                AnyAPIMethod(method: Call_testAsyncThrowingMethod.self),
                AnyAPIMethod(method: Call_testMultipleArguments_firstName_String_lastName_String.self)
            ]

            private struct Call_testUnnamedStringParameter__String: APIMethodCall {
                typealias API = BasicTestAPI
                typealias ReturnType = String
                static let methodID: APIMethodID = "testUnnamedStringParameter(_: String) -> String"
                var parameter0: String

                enum CodingKeys: String, CodingKey {
                    case parameter0 = "0"
                }

                func call(on api: API) async throws -> String {
                    api.testUnnamedStringParameter(
                        parameter0
                    )
                }
            }

            private struct Call_testThrowingMethod: APIMethodCall {
                typealias API = BasicTestAPI
                typealias ReturnType = String
                static let methodID: APIMethodID = "testThrowingMethod() -> String"

                func call(on api: API) async throws -> String {
                    try api.testThrowingMethod(

                    )
                }
            }

            private struct Call_testAsyncMethod: APIMethodCall {
                typealias API = BasicTestAPI
                typealias ReturnType = String
                static let methodID: APIMethodID = "testAsyncMethod() -> String"

                func call(on api: API) async throws -> String {
                    await api.testAsyncMethod(

                    )
                }
            }

            private struct Call_testAsyncThrowingMethod: APIMethodCall {
                typealias API = BasicTestAPI
                typealias ReturnType = String
                static let methodID: APIMethodID = "testAsyncThrowingMethod() -> String"

                func call(on api: API) async throws -> String {
                    try await api.testAsyncThrowingMethod(

                    )
                }
            }

            private struct Call_testMultipleArguments_firstName_String_lastName_String: APIMethodCall {
                typealias API = BasicTestAPI
                typealias ReturnType = String
                static let methodID: APIMethodID = "testMultipleArguments(firstName: String, lastName: String) -> String"
                var parameter0: String
                var parameter1: String

                enum CodingKeys: String, CodingKey {
                    case parameter0 = "0_firstName"
                    case parameter1 = "1_lastName"
                }

                func call(on api: API) async throws -> String {
                    api.testMultipleArguments(
                        firstName: parameter0,
                        lastName: parameter1
                    )
                }
            }
        }
        
        extension MiddlewareTestAPI {
            static let remotelyCallableMethods: [AnyAPIMethod<MiddlewareTestAPI>] = [
                AnyAPIMethod(method: Call_testBearerToken.self)
            ]

            private struct Call_testBearerToken: APIMethodCall {
                typealias API = MiddlewareTestAPI
                typealias ReturnType = String
                static let methodID: APIMethodID = "testBearerToken() -> String"

                func call(on api: API) async throws -> String {
                    api.testBearerToken(

                    )
                }
            }
        }
        
        extension ValidationTestAPI {
            static let remotelyCallableMethods: [AnyAPIMethod<ValidationTestAPI>] = [
                AnyAPIMethod(method: Call_testValidatable_with_NewUserInfo.self)
            ]

            private struct Call_testValidatable_with_NewUserInfo: APIMethodCall {
                typealias API = ValidationTestAPI
                typealias ReturnType = NoReturnValue
                static let methodID: APIMethodID = "testValidatable(with: NewUserInfo) -> Void"
                var parameter0: NewUserInfo

                enum CodingKeys: String, CodingKey {
                    case parameter0 = "0_with"
                }

                func call(on api: API) async throws -> NoReturnValue {
                    try api.testValidatable(
                        with: parameter0
                    )
                    return NoReturnValue()
                }
            }
        }
        
        private struct APITypesMustBeCodable<T: Codable> {
        }
        """####
        
        let analysisCore = AnalysisCore()
        try analysisCore.analyze(sourceString: source, path: URL(string: "file:///test.swift")!)
        let generatorCore = GeneratorCore(sourceInfo: analysisCore.info, serverCodeWarnings: ["A test warning", "Another test warning"])
        let (serverSource, clientSource) = try generatorCore.generateSource()
        
//        print(serverSource)
        assertEqualAndPrintDiff(actual: serverSource, expected: expectedServerSource)
    }
}

func assertEqualAndPrintDiff(
    actual: String,
    expected: String,
    file: StaticString = #file,
    line: UInt = #line
) {
    let actualLines = actual
        .components(separatedBy: .newlines)
    let expectedLines = expected.components(separatedBy: .newlines)
    let differences = actualLines.difference(from: expectedLines)
    
    guard differences.count > 0 else {
        return
    }
    
    var insertionByOffset: [Int: String] = [:]
    var removalByOffset: [Int: String] = [:]
    for difference in differences {
        switch difference {
        case let .insert(offset, element, _):
            insertionByOffset[offset] = element
        case let .remove(offset, element, _):
            removalByOffset[offset] = element
        }
    }
    
    var actualLinesIndex = 0
    var expectedLinesIndex = 0
    var differenceDescriptionLines: [String] = []
    var previousLineWasADifference = false
    while
        actualLines.indices.contains(actualLinesIndex)
            || expectedLines.indices.contains(expectedLinesIndex)
    {
        if let removedLine = removalByOffset[expectedLinesIndex] {
            differenceDescriptionLines.append("- \(expectedLinesIndex + 1): \(removedLine)")
            expectedLinesIndex += 1
            previousLineWasADifference = true
        } else if let insertedLine = insertionByOffset[actualLinesIndex] {
            differenceDescriptionLines.append("+ \(actualLinesIndex + 1): \(insertedLine)")
            actualLinesIndex += 1
            previousLineWasADifference = true
        } else {
            actualLinesIndex += 1
            expectedLinesIndex += 1
            if previousLineWasADifference {
                differenceDescriptionLines.append("  \(expectedLinesIndex): \(expectedLines[expectedLinesIndex - 1])")
                previousLineWasADifference = false
            } else if removalByOffset[expectedLinesIndex] != nil || insertionByOffset[actualLinesIndex] != nil {
                // Next line is a difference. Print the line before:
                differenceDescriptionLines.append("...")
                differenceDescriptionLines.append("  \(expectedLinesIndex): \(expectedLines[expectedLinesIndex - 1])")
            }
        }
    }
    
    let message = """
    The actual String does not match the expected one.
    
    Differences:
    \(differenceDescriptionLines.joined(separator: "\n"))
    
    """
    
    XCTFail(message)
}
