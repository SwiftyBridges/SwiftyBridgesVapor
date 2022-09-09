import FluentKit

/// Fluent's property wrappers such as `Field` or `Children` can be embedded in `HiddenFromClient` to hide those fields from the client. This is useful for fields that are not meant to be exposed to the client, but are still needed for the server.
///
/// For example, `@Field(key: "password_hash") var passwordHash: String` would be replaced by `@HiddenFromClient(Field(key: "password_hash")) var passwordHash: String` in order to hide it from the client.
///
/// There are two important distinctions to using the property wrappers by themselves :
/// - Such properties are not encoded or decoded when the model ist sent or received from the client.
/// - Such properties are not included in the client struct when the model conforms to `GenerateClientStruct`.
///
/// - warning: When a model is received from the client, a property using this property wrapper MUST be given a value before it is accessed. Otherwhise, the server will crash.
@propertyWrapper
public class HiddenFromClient<PropertyWrapper: _FluentProperty> {
    private var property: PropertyWrapper
    
    public init(_ property: PropertyWrapper) {
        self.property = property
    }

    public var wrappedValue: PropertyWrapper.Value {
        get {
            return property.wrappedValue
        }
        set {
            property.wrappedValue = newValue
        }
    }

    public var projectedValue: PropertyWrapper {
        property
    }
}

extension HiddenFromClient: Property where PropertyWrapper: Property {
    public typealias Model = PropertyWrapper.Model
    public typealias Value = PropertyWrapper.Value
    public var value: Value? {
        get { property.value }
        set { property.value = newValue }
    }
}

extension HiddenFromClient: AnyProperty where PropertyWrapper: AnyProperty {}

extension HiddenFromClient: AnyDatabaseProperty where PropertyWrapper: AnyDatabaseProperty {
    public var keys: [FieldKey] {
        property.keys
    }
    
    public func input(to input: DatabaseInput) {
        property.input(to: input)
    }
    
    public func output(from output: DatabaseOutput) throws {
        try property.output(from: output)
    }
}

extension HiddenFromClient: QueryableProperty where PropertyWrapper: QueryableProperty {
    public static func queryValue(_ value: Value) -> DatabaseQuery.Value {
        PropertyWrapper.queryValue(value)
    }
}

extension HiddenFromClient: AnyQueryableProperty where PropertyWrapper: AnyQueryableProperty {
    public var path: [FieldKey] {
        property.path
    }
    
    public func queryableValue() -> DatabaseQuery.Value? {
        property.queryableValue()
    }
}

public protocol _FluentProperty: Property {
    var wrappedValue: Value { get set }
}

extension BooleanProperty: _FluentProperty {}
extension ChildrenProperty: _FluentProperty {}
extension EnumProperty: _FluentProperty {}
extension FieldProperty: _FluentProperty {}
extension GroupProperty: _FluentProperty {}
extension OptionalBooleanProperty: _FluentProperty {}
extension OptionalChildProperty: _FluentProperty {}
extension OptionalEnumProperty: _FluentProperty {}
extension OptionalFieldProperty: _FluentProperty {}
extension OptionalParentProperty: _FluentProperty {}
extension ParentProperty: _FluentProperty {}
extension SiblingsProperty: _FluentProperty {}
extension TimestampProperty: _FluentProperty {}
