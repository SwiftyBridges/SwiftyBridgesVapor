import Foundation
import SwiftSyntax

/// Represents a custom attribute (such as a property wrapper) of a variable or property declaration
struct CustomVarAttribute {
    var name: String
    
    init(_ syntax: CustomAttributeSyntax) {
        name = syntax.attributeName.description
    }
}
