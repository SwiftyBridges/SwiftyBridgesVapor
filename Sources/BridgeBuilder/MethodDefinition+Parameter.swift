import Foundation
import SwiftSyntax

extension MethodDefinition {
    /// Infos about a method parameter
    struct Parameter {
        var firstName: String?
        var secondName: String?
        var typeName: String
    }
}

// MARK: - Additional Initializer

extension MethodDefinition.Parameter {
    init(_ syntax: FunctionParameterSyntax) {
        let typeName = syntax.type.trimmedDescription
        firstName = syntax.firstName.trimmedDescription
        secondName = syntax.secondName?.trimmedDescription
        self.typeName = typeName
    }
}

extension MethodDefinition.Parameter: CustomReflectable {
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
