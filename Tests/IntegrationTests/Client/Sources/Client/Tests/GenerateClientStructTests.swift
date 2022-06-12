import Foundation
@testable import SwiftyBridgesClient

func testGenerateClientStruct() async throws {
    let structAPI = GenerateClientStructTestAPI(url: serverURL)
    
    // Test if `GenerateHashable` works:
    _ = [Dog: String]()
    
    _ = try await structAPI.testSimpleStruct(Name(firstName: "First", lastName: "Last"))
    
    print("Testing empty array model references...")
    var person = Person(id: UUID(), name: "Jon", dogs: [], youngerSiblings: [])
    var returnedPerson = try await structAPI.testPerson(person)
    assert(returnedPerson == person, "Persons did not match")
    
    print("Testing nil @OptionalChild...")
    var cat = Cat(id: UUID(), name: "Garfield", bestDogFriend: nil)
    var returnedCat = try await structAPI.testCat(cat)
    assert(returnedCat == cat, "Cats did not match")
    
    print("Testing nil model references...")
    var dog = Dog(id: UUID(), name: "Odie", owner: person.id!, sitter: nil, bestCatFriend: nil)
    var returnedDog = try await structAPI.testDog(dog)
    assert(returnedDog == dog, "Dogs did not match!")
    
    print("Testing @OptionalParent with ID...")
    let person2 = Person(id: UUID(), name: "Doc Boy", dogs: [], youngerSiblings: [])
    dog.sitter = person2.id!
    dog.bestCatFriend = cat.id!
    returnedDog = try await structAPI.testDog(dog)
    assert(returnedDog == dog, "Dogs did not match!")
    
    print("Testing model references with object...")
    returnedDog = try await structAPI.testDog(dog, owner: person, sitter: person2, bestCatFriend: cat)
    dog.owner = person.id!
    dog.sitter = person2.id!
    dog.bestCatFriend = cat.id!
    assert(returnedDog == dog, "Dogs did not match!")
    assert(returnedDog.$owner == person, "Dogs' owners did not match!")
    assert(returnedDog.$sitter == person2, "Dogs' sitters did not match!")
    assert(returnedDog.$bestCatFriend == cat, "Dogs' best cat friends did not match!")
    
    print("Testing @OptionalChild with object...")
    returnedCat = try await structAPI.testCat(cat, bestDogFriend: dog)
    cat.bestDogFriend = dog.id!
    assert(returnedCat == cat, "Cats did not match")
    assert(returnedCat.$bestDogFriend == dog, "Cats' best dog friends did not match")
    
    print("Testing filled array model references...")
    returnedPerson = try await structAPI.testPerson(person, dogs: [dog], youngerSiblings: [person2])
    person.dogs = [dog]
    person.youngerSiblings = [person2]
    assert(returnedPerson == person, "Persons did not match")
    
    print("Testing that ID and object in @Parent and @OptionalParent always match...")
    var testDog = returnedDog
    testDog.owner = UUID()
    assert(testDog.$owner == nil, "Projected value of @Parent was not reset")
    testDog.sitter = nil
    assert(testDog.$sitter == nil, "Projected value of @OptionalParent was not reset")
    
    print("Testing that FluentModelStructs can be saved and loaded via Codable...")
    let jsonEncoder = JSONEncoder()
    let jsonDecoder = JSONDecoder()
    assert(returnedDog.$owner != nil)
    assert(returnedDog.$sitter != nil)
    assert(returnedDog.$bestCatFriend != nil)
    var loadedDog = try jsonDecoder.decode(Dog.self, from: jsonEncoder.encode(returnedDog))
    assert(loadedDog == returnedDog, "Dogs did not match")
    assert(loadedDog.$owner == returnedDog.$owner, "Owner was not persisted")
    assert(loadedDog.$sitter == returnedDog.$sitter, "Sitter was not persisted")
    assert(loadedDog.$bestCatFriend == returnedDog.$bestCatFriend, "Best cat friend was not persisted")
    
    assert(returnedCat.$bestDogFriend != nil)
    var loadedCat = try jsonDecoder.decode(Cat.self, from: jsonEncoder.encode(returnedCat))
    assert(loadedCat.$bestDogFriend == returnedCat.$bestDogFriend, "Best dog friend was not persisted")
    
    assert(!person.dogs.isEmpty)
    assert(!person.youngerSiblings.isEmpty)
    var loadedPerson = try jsonDecoder.decode(Person.self, from: jsonEncoder.encode(person))
    assert(loadedPerson == person, "Persons did not match")
    
    print("testing that only necessary Fluent data is sent to server...")
    assert(returnedDog.$owner != nil)
    assert(returnedDog.$sitter != nil)
    assert(returnedDog.$bestCatFriend != nil)
    try Environment.$encodingForFluent.withValue(true) {
        loadedDog = try jsonDecoder.decode(Dog.self, from: jsonEncoder.encode(returnedDog))
    }
    assert(loadedDog.owner == returnedDog.owner)
    assert(loadedDog.$owner == nil, "Full owner was encoded")
    assert(loadedDog.sitter == returnedDog.sitter)
    assert(loadedDog.$sitter == nil, "Full sitter was encoded")
    assert(loadedDog.bestCatFriend == returnedDog.bestCatFriend)
    assert(loadedDog.$bestCatFriend == nil, "Full best cat friend was encoded")
    
    assert(returnedCat.$bestDogFriend != nil)
    try Environment.$encodingForFluent.withValue(true) {
        loadedCat = try jsonDecoder.decode(Cat.self, from: jsonEncoder.encode(returnedCat))
    }
    assert(loadedCat.bestDogFriend == nil, "Best dog friend was encoded")
    assert(loadedCat.$bestDogFriend == nil)
    
    assert(!person.dogs.isEmpty)
    assert(!person.youngerSiblings.isEmpty)
    try Environment.$encodingForFluent.withValue(true) {
        loadedPerson = try jsonDecoder.decode(Person.self, from: jsonEncoder.encode(person))
    }
    assert(loadedPerson.dogs.isEmpty, "All dogs were encoded")
    assert(loadedPerson.youngerSiblings.isEmpty, "All younger siblings were encoded")
    
    print("Testing TestStructs and TestClasses")
    let _: GenerateClientStructTestStruct
    assert(GenerateEquatableTestStruct() == GenerateEquatableTestStruct())
    let _: [GenerateHashableTestStruct: String]
    let _: GenerateClientStructTestClass
    assert(GenerateEquatableTestClass() == GenerateEquatableTestClass())
    let _: [GenerateHashableTestClass: String]
}
