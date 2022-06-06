import Foundation

/// Conforming a type to this protocol signals to SwiftyBridges that it shall generate an extension of the type to `Equatable` in the client code
///
/// Conforming a type to this protocol generates the following extension in the client code to tell the compiler to synthesize `Equatable` conformance:
/// ```
/// extension TypeName: Equatable {}
/// ```
/// `GenerateEquatable` is usually used together with `GenerateClientStruct`. All types used in the type must be Equatable themselves.
///
/// - Warning: The protocol conformance must be declared in the original definition of the type and not in an extension.
public protocol GenerateEquatable {}
