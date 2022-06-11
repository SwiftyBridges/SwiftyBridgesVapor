import Foundation
import SwiftSyntax

/// Infos about a property of a type used by an API definition
struct InstanceProperty {
    /// The property name
    var name: String
    
    /// The type of the property
    var type: String?
    
    /// Would contian `binding: String` for this property
    var binding: String
    
    /// Contains the documentation comments of the property
    var leadingTrivia: String
    
    /// Contaings info about the custom attributes (such as property wrappers) of the property
    var customAttributes: [CustomVarAttribute]
    
    var bindingSyntax: PatternBindingSyntax
}

extension InstanceProperty: CustomReflectable {
    /// This is needed so that the computed properties are found by Stencil
    var customMirror: Mirror {
        Mirror(
            self,
            children: [
                "name": name,
                "type": type as Any,
                "binding": binding,
                "leadingTrivia": leadingTrivia,
                "customAttributes": customAttributes,
                "clientPropertyDeclaration": clientPropertyDeclaration,
            ]
        )
    }
    
    var clientPropertyDeclaration: String {
        var bindingString = binding
        var attribute: String? = nil
        
        if
            self.hasAttribute(named: "Parent")
                || self.hasAttribute(named: "Fluent.Parent"),
            let type = type
        {
            attribute = "@SwiftyBridgesClient.Parent<\(type)>"
            bindingString = "\(name): \(type).IDValue"
        } else if
            self.hasAttribute(named: "OptionalParent")
                || self.hasAttribute(named: "Fluent.OptionalParent"),
            let nonOptionalType = bindingSyntax.typeAnnotation?.type.nonOptionalType?.description
        {
            attribute = "@SwiftyBridgesClient.OptionalParent<\(nonOptionalType)>"
            bindingString = "\(name): \(nonOptionalType).IDValue?"
        } else if
            self.hasAttribute(named: "OptionalChild")
                || self.hasAttribute(named: "Fluent.OptionalChild"),
            let nonOptionalType = bindingSyntax.typeAnnotation?.type.nonOptionalType?.description
        {
            attribute = "@SwiftyBridgesClient.OptionalChild<\(nonOptionalType)>"
            bindingString = "\(name): \(nonOptionalType).IDValue?"
        } else if
            self.hasAttribute(named: "Children")
                || self.hasAttribute(named: "Fluent.Children")
        {
            attribute = "@SwiftyBridgesClient.Children"
        } else if
            self.hasAttribute(named: "Siblings")
                || self.hasAttribute(named: "Fluent.Siblings")
        {
            attribute = "@SwiftyBridgesClient.Siblings"
        }
        
        
        var declaration = "var \(bindingString)"
        if let attribute = attribute {
            declaration = "\(attribute)\n\(declaration)"
        }
        return declaration
    }
    
    func hasAttribute(named name: String) -> Bool {
        customAttributes.contains(where: { $0.name == name })
    }
}

extension TypeSyntax {
    /// Returns the wrapped type if `self` is an Optional. If `self` is not optional, returns nil.
    var nonOptionalType: TypeSyntax? {
        if
            let optionalSyntax = self.as(OptionalTypeSyntax.self)
        {
            return optionalSyntax.wrappedType
        }
        else if
            let simpleSyntax = self.as(SimpleTypeIdentifierSyntax.self),
            simpleSyntax.name.description == "Optional"
                || simpleSyntax.name.description == "Swift.Optional"
        {
            return simpleSyntax.genericArgumentClause?.arguments.first?.argumentType
        }
        
        return nil
    }
}
