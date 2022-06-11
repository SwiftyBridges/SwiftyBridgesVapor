import Foundation

func testValidations() async throws {
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
}
