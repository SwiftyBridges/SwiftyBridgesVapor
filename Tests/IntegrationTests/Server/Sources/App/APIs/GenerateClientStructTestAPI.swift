import Fluent
import SwiftyBridges
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
    var bestDogFriend: Dog?
    
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
