import Foundation

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
        
        if self.hasAttribute(named: "Children")
            || self.hasAttribute(named: "Fluent.Children")
            || self.hasAttribute(named: "Siblings")
            || self.hasAttribute(named: "Fluent.Siblings"),
           let type = type
        {
            // We need to make the type optional, because Fluent does not encode the attribute if it has not been fetched:
            bindingString = "\(name): \(type)?"
        }
        else if
            self.hasAttribute(named: "Parent")
                || self.hasAttribute(named: "Fluent.Parent")
                || self.hasAttribute(named: "OptionalParent")
                || self.hasAttribute(named: "Fluent.OptionalParent"),
            let type = type
        {
            bindingString = "\(name): SwiftyBridgesClient.ParentReference< \(type) >"
        }

        
        return "var \(bindingString)"
    }
    
    func hasAttribute(named name: String) -> Bool {
        customAttributes.contains(where: { $0.name == name })
    }
}
