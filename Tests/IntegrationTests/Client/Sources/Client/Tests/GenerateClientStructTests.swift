import Foundation

func testGenerateClientStruct() async throws {
    let structAPI = GenerateClientStructTestAPI(url: serverURL)
    
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
    
    // Test if `GenerateHashable` works:
    _ = [Dog: String]()
}
