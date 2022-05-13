import Foundation

/// Infos about a property of a type used by an API definition
struct InstanceProperty {
    /// Would contian `binding: String` for this property
    var binding: String
    
    /// Contains the documentation comments of the property
    var leadingTrivia: String
}

extension InstanceProperty: CustomReflectable {
    /// This is needed so that the computed properties are found by Stencil
    var customMirror: Mirror {
        Mirror(
            self,
            children: [
                "binding": binding,
                "leadingTrivia": leadingTrivia,
                "clientPropertyDeclaration": clientPropertyDeclaration,
            ]
        )
    }
    
    var clientPropertyDeclaration: String {
        "var " + binding
    }
}
