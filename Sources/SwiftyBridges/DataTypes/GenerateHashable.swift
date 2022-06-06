import Foundation

/// Conforming a type to this protocol signals to SwiftyBridges that it shall generate an extension of the type to `Hashable` in the client code
///
/// Conforming a type to this protocol generates the following extension in the client code to tell the compiler to synthesize `Hashable` conformance:
/// ```
/// extension TypeName: Hashable {}
/// ```
/// `GenerateHashable` is usually used together with `GenerateClientStruct`. All types used in the type must be Hashable themselves.
///
/// - Warning: The protocol conformance must be declared in the original definition of the type and not in an extension.
public protocol GenerateHashable {}
