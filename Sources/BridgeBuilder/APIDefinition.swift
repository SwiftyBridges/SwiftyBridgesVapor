//
//  APIDefinition.swift
//  APIDefinition
//
//  Created by Stephen Kockentiedt on 18.09.21.
//

import Foundation
import SwiftSyntax

struct APIDefinition {
    var name: String
    var leadingTrivia: String
    var publicMethods: [MethodDefinition] = []
    var structSyntax: StructDeclSyntax
}
