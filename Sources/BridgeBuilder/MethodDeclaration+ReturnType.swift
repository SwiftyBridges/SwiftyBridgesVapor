//
//  File.swift
//  File
//
//  Created by Stephen Kockentiedt on 18.09.21.
//

import Foundation

extension MethodDefinition {
    /// Infos about the return type of an API method
    enum ReturnType {
        case void
        case codable(typeName: String)
        case voidEventLoopFuture
        case codableEventLoopFuture(valueTypeName: String)
    }
}

extension MethodDefinition.ReturnType: CustomReflectable {
    var customMirror: Mirror {
        Mirror(
            self,
            children: [
                "effectiveReturnTypeName": effectiveReturnTypeName,
                "codableEffectiveReturnTypeName": codableEffectiveReturnTypeName,
                "isFuture": isFuture,
            ]
        )
    }
    
    var effectiveReturnTypeName: String {
        switch self {
        case .void, .voidEventLoopFuture:
            return "Void"
        case .codable(let typeName), .codableEventLoopFuture(let typeName):
            return typeName
        }
    }
    
    /// This is the same as `effectiveReturnTypeName` only that `Void` is replaced by `NoReturnValue`. This is needed so that the generated code compiles because `Void` does noch conform to `Codable`.
    var codableEffectiveReturnTypeName: String {
        switch self {
        case .void, .voidEventLoopFuture:
            return "NoReturnValue"
        case .codable(let typeName), .codableEventLoopFuture(let typeName):
            return typeName
        }
    }
    
    var isFuture: Bool {
        switch self {
        case .void, .codable:
            return false
        case .voidEventLoopFuture, .codableEventLoopFuture:
            return true
        }
    }
}
