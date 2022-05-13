import Foundation

/// Conforming a type to this protocol signals to SwiftyBridges that it shall generate a struct having the same `Codable` signature as this type and add it to the generated client code. This way, such a type can be used as a parameter or return type of a method in an `APIDefinition`. Fluent models or plain structs are usually used for this purpose.
public protocol GenerateClientStruct: Codable {}
