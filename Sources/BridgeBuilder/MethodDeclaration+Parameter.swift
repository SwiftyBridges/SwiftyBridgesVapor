//
//  File.swift
//  File
//
//  Created by Stephen Kockentiedt on 18.09.21.
//

import Foundation
import SwiftSyntax

extension MethodDeclaration {
    struct Parameter {
        var firstName: String?
        var secondName: String?
        var typeName: String
    }
}

// MARK: - Additional Initializer

extension MethodDeclaration.Parameter {
    init(_ syntax: FunctionParameterSyntax) {
        guard let typeName = syntax.type?.withoutTrivia().description else {
            fatalError("Could not parse method argument '\(syntax.withTrailingComma(nil).withoutTrivia().description)'")
        }
        
        firstName = syntax.firstName?.withoutTrivia().description
        secondName = syntax.secondName?.withoutTrivia().description
        self.typeName = typeName
    }
}

extension MethodDeclaration.Parameter: CustomReflectable {
    /// This is needed so that the computed properties are found by Stencil
    var customMirror: Mirror {
        Mirror(
            self,
            children: [
                "firstName": firstName as Any,
                "secondName": secondName as Any,
                "typeName": typeName,
                "label": label as Any,
                "variableName": variableName,
                "combinedNames": combinedNames,
            ]
        )
    }
    
    var label: String? {
        if firstName == "_" {
            return nil
        }
        
        return firstName
    }
    
    var variableName: String {
        secondName ?? firstName ?? "_"
    }
    
    var combinedNames: String {
        [firstName, secondName]
            .compactMap { $0 }
            .joined(separator: " ")
    }
}
