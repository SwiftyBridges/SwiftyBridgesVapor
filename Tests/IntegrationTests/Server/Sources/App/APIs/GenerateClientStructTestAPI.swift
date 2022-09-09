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
