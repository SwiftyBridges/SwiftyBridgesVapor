import Foundation

extension MethodDefinition {
    /// Infos about the return type of an API method
    enum ReturnType {
        case void
        case codable(typeName: String)
    }
}

extension MethodDefinition.ReturnType: CustomReflectable {
    var customMirror: Mirror {
        Mirror(
            self,
            children: [
                "effectiveReturnTypeName": effectiveReturnTypeName,
                "codableEffectiveReturnTypeName": codableEffectiveReturnTypeName,
            ]
        )
    }
    
    var effectiveReturnTypeName: String {
        switch self {
        case .void:
            return "Void"
        case .codable(let typeName):
            return typeName
        }
    }
    
    /// This is the same as `effectiveReturnTypeName` only that `Void` is replaced by `NoReturnValue`. This is needed so that the generated code compiles because `Void` does noch conform to `Codable`.
    var codableEffectiveReturnTypeName: String {
        switch self {
        case .void:
            return "NoReturnValue"
        case .codable(let typeName):
            return typeName
        }
    }
}
