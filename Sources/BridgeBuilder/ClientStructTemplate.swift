import Foundation
import SwiftSyntax

struct ClientStructTemplate {
    var name: String
    var leadingTrivia: String
    var isFluentModel: Bool
    var instanceProperties: [InstanceProperty] = []
    var classOrStructSyntax: DeclSyntaxProtocol
}
