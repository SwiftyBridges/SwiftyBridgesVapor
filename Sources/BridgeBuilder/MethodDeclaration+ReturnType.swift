//
//  File.swift
//  File
//
//  Created by Stephen Kockentiedt on 18.09.21.
//

import Foundation

extension MethodDeclaration {
    enum ReturnType {
        case void
        case codable(typeName: String)
        case voidEventLoopFuture
        case codableEventLoopFuture(valueTypeName: String)
    }
}

extension MethodDeclaration.ReturnType: CustomReflectable {
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
