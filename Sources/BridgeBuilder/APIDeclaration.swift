//
//  APIDeclaration.swift
//  APIDeclaration
//
//  Created by Stephen Kockentiedt on 18.09.21.
//

import Foundation
import SwiftSyntax

struct APIDeclaration {
    var name: String
    var leadingTrivia: String
    var publicMethods: [MethodDeclaration] = []
    var structSyntax: StructDeclSyntax
}
