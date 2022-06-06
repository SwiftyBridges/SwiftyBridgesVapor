import Foundation

let serverURL = URL(string: "http://127.0.0.1:8080/api")!

@main
struct Client {
    static func main() async throws {
        let basicAPI = BasicTestAPI(url: serverURL)
        
        _ = try await basicAPI.testAsyncMethod()
        _ = try await basicAPI.testAsyncThrowingMethod()
        _ = try await basicAPI.testMultipleArguments(firstName: "First", lastName: "Last")
        _ = try await basicAPI.testThrowingMethod()
        _ = try await basicAPI.testUnnamedStringParameter("A string")
        
        let structAPI = GenerateClientStructTestAPI(url: serverURL)
        
        _ = try await structAPI.testSimpleStruct(Name(firstName: "First", lastName: "Last"))
        
        print("Testing nil array model references...")
        var person = Person(id: UUID(), name: "Jon", dogs: nil, youngerSiblings: nil)
        var returnedPerson = try await structAPI.testPerson(person)
        assert(returnedPerson == person, "Persons did not match")
        
        print("Testing nil @OptionalChild...")
        var cat = Cat(id: UUID(), name: "Garfield", bestDogFriend: nil)
        var returnedCat = try await structAPI.testCat(cat)
        assert(returnedCat == cat, "Cats did not match")
        
        print("Testing nil model references...")
        var dog = Dog(id: UUID(), name: "Odie", owner: .init(id: person.id!), sitter: .init(id: nil), bestCatFriend: .init(id: nil))
        var returnedDog = try await structAPI.testDog(dog)
        assert(returnedDog == dog, "Dogs did not match!")
        
        print("Testing @OptionalParent with ID...")
        let person2 = Person(id: UUID(), name: "Doc Boy", dogs: nil, youngerSiblings: nil)
        dog.sitter = .init(id: person2.id!)
        dog.bestCatFriend = .init(id: cat.id!)
        returnedDog = try await structAPI.testDog(dog)
        assert(returnedDog == dog, "Dogs did not match!")
        
        print("Testing model references with object...")
        returnedDog = try await structAPI.testDog(dog, owner: person, sitter: person2, bestCatFriend: cat)
        dog.owner = .init(person)!
        dog.sitter = .init(person2)!
        dog.bestCatFriend = .init(cat)!
        assert(returnedDog == dog, "Dogs did not match!")
        dog.owner = .init(id: person.id!)
        dog.sitter = .init(id: nil)
        dog.bestCatFriend = .init(id: nil)
        
        print("Testing @OptionalChild with object...")
        returnedCat = try await structAPI.testCat(cat, bestDogFriend: dog)
        cat.bestDogFriend = dog
        assert(returnedCat == cat, "Cats did not match")
        cat.bestDogFriend = nil
        
        print("Testing filled array model references...")
        returnedPerson = try await structAPI.testPerson(person, dogs: [dog], youngerSiblings: [person2])
        person.dogs = [dog]
        person.youngerSiblings = [person2]
        assert(returnedPerson == person, "Persons did not match")
        
        let validationAPI = ValidationTestAPI(url: serverURL)
        try await validationAPI.testValidatable(with: NewUserInfo(name: "A name", email: "a@bc.de", password: "Very secret!"))
        print("Testing validation errors...")
        do {
            try await validationAPI.testValidatable(with: NewUserInfo(name: "", email: "a@bc.de", password: "Very secret!"))
            fatalError("testValidatable() should have thrown an error")
        } catch {}
        do {
            try await validationAPI.testValidatable(with: NewUserInfo(name: "A name", email: "abc.de", password: "Very secret!"))
            fatalError("testValidatable() should have thrown an error")
        } catch {}
        do {
            try await validationAPI.testValidatable(with: NewUserInfo(name: "A name", email: "a@bc.de", password: "short"))
            fatalError("testValidatable() should have thrown an error")
        } catch {}
        
        var middlewareAPI = MiddlewareTestAPI(url: serverURL, bearerToken: "testToken")
        _ = try await middlewareAPI.testBearerToken()
        
        print("Testing middleware errors...")
        middlewareAPI = MiddlewareTestAPI(url: serverURL, bearerToken: "wrong token")
        do {
            _ = try await middlewareAPI.testBearerToken()
            fatalError("test() should have thrown an error")
        } catch {}
        
        // Test if `GenerateHashable` works:
        _ = [Dog: String]()
        
        print("\nAll tests passed!!!")
    }
}
