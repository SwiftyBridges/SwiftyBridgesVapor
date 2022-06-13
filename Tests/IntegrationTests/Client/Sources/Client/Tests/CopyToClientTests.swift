import Foundation

func testCopyToClient() async throws {
    _ = CopyToClientEnum.firstCase
    let s = CopyToClientStruct(storedProperty: 42)
    _ = s.computedProperty
    _ = s.methodInExtension()
    let c = CopyToClientClass(storedProperty: 42)
    _ = c.computedProperty
}
