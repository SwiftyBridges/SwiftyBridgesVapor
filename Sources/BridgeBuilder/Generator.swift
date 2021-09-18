//
//  Generator.swift
//  Generator
//
//  Created by Stephen Kockentiedt on 16.09.21.
//

import Foundation
import Stencil
import StencilSwiftKit

class Generator {
    private let apiDeclarations: [APIDeclaration]
    private let serverOutputFile: String
    private let clientOutputFile: String
    
    init(apiDeclarations: [APIDeclaration], serverOutputFile: String, clientOutputFile: String) {
        self.apiDeclarations = apiDeclarations
        self.serverOutputFile = serverOutputFile
        self.clientOutputFile = clientOutputFile
    }
    
    func run() throws {
        let context = ["apiDeclarations": apiDeclarations]
        let environment = Environment(
            loader: FileSystemLoader(bundle: [Bundle.module]),
            templateClass: StencilSwiftTemplate.self // <- Prevents ugly newlines in generated code
        )
        
        let serverSource = try environment.renderTemplate(name: "Templates/ServerTemplate.swift.stencil", context: context)
        try Data(serverSource.utf8)
            .write(to: URL(fileURLWithPath: serverOutputFile))
        
        let clientSource = try environment.renderTemplate(name: "Templates/ClientTemplate.swift.stencil", context: context)
        try Data(clientSource.utf8)
            .write(to: URL(fileURLWithPath: clientOutputFile))
    }
}
