//
//  MethodDefinition.swift
//  MethodDefinition
//
//  Created by Stephen Kockentiedt on 18.09.21.
//

import Foundation

/// Infos about an API method
struct MethodDefinition {
    var name: String
    
    /// Contains the documentation comments of the method
    var leadingTrivia: String
    
    var isInlinable: Bool
    var parameters: [Parameter]
    var isAsync: Bool
    var mayThrow: Bool
    var returnType: ReturnType
    var filePath: String
    var lineNumber: Int
}

extension MethodDefinition: CustomReflectable {
    /// This is needed so that the computed properties are found by Stencil
    var customMirror: Mirror {
        Mirror(
            self,
            children: [
                "name": name,
                "leadingTrivia": leadingTrivia,
                "isInlinable": isInlinable,
                "parameters": parameters,
                "isAsync": isAsync,
                "mayThrow": mayThrow,
                "returnType": returnType,
                "filePath": filePath,
                "lineNumber": lineNumber,
                "clientMethodSignature": clientMethodSignature,
                "methodID": methodID,
                "generatedTypeName": generatedTypeName,
                "returnsVoid": returnsVoid,
            ]
        )
    }
    
    var clientMethodSignature: String {
        let parameterList = parameters
            .map { $0.combinedNames + ": " + $0.typeName }
            .joined(separator: ", ")
        return "(\(parameterList)) async throws -> \(returnType.effectiveReturnTypeName)"
    }
    
    var methodID: String {
        let parameterPart = parameters.map { parameter -> String in
            "\(parameter.firstName.map { $0 + ": " } ?? "")\(parameter.typeName)"
        }
            .joined(separator: ", ")
        
        return "\(name)(\(parameterPart)) -> \(returnType.effectiveReturnTypeName)"
    }
    
    var generatedTypeName: String {
        let parameterPart = parameters.map { parameter -> String in
            let typeName = parameter.typeName
                .replacingOccurrences(of: ".", with: "_")
                .replacingOccurrences(of: "<", with: "_")
                .replacingOccurrences(of: ">", with: "_")
                .replacingOccurrences(of: ",", with: "_")
                .replacingOccurrences(of: " ", with: "")
            return "\(parameter.label ?? "")_\(typeName)"
        }
            .joined(separator: "_")
        
        if parameterPart.isEmpty {
            return "Call_\(name)"
        } else {
            return "Call_\(name)_\(parameterPart)"
        }
    }
    
    var returnsVoid: Bool {
        returnType.effectiveReturnTypeName == "Void"
    }
}
