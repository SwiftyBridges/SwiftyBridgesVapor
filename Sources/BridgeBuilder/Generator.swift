//
//  Generator.swift
//  Generator
//
//  Created by Stephen Kockentiedt on 16.09.21.
//

import Foundation
import PathKit
import Stencil

/// Generates communication code for API definitions parsed by `Analysis` for both server and client.
class Generator {
    private let potentiallyUsedImports: Set<String>
    private let apiDefinitions: [APIDefinition]
    private let clientStructTemplates: [ClientStructTemplate]
    
    /// Contains a list of extensions that shall be generated to signal protocol conformance
    private let protocolConformanceExtensions: [ProtocolConformance]
    
    private let serverCodeWarnings: [String]
    private let serverOutputFile: String
    private let clientOutputFile: String
    
    /// Default initializer
    /// - Parameters:
    ///   - potentiallyUsedImports: Names of modules that the used API types may need and that shall be conditionally imported into the generated code
    ///   - apiDefinitions: Definition infos generated by `Analysis`
    ///   - clientStructTemplates: Client Struct Templates generated by `Analysis`
    ///   - protocolConformanceExtensions: Protocol conformance infos generated by `Analysis`
    ///   - serverCodeWarnings: Warnings that shall be emitted into the generated server code
    ///   - serverOutputFile: Path to the swift file that shall be generated for the server
    ///   - clientOutputFile: Path to the swift file that shall be generated for the client
    init(
        potentiallyUsedImports: Set<String>,
        apiDefinitions: [APIDefinition],
        clientStructTemplates: [ClientStructTemplate],
        protocolConformanceExtensions: [ProtocolConformance],
        serverCodeWarnings: [String],
        serverOutputFile: String,
        clientOutputFile: String
    ) {
        self.potentiallyUsedImports = potentiallyUsedImports
        self.apiDefinitions = apiDefinitions
        self.clientStructTemplates = clientStructTemplates
        self.protocolConformanceExtensions = protocolConformanceExtensions
        self.serverCodeWarnings = serverCodeWarnings
        self.serverOutputFile = serverOutputFile
        self.clientOutputFile = clientOutputFile
    }
    
    /// Generates the code and writes it to the given output file paths.
    func run() throws {
        let conditionalImports = potentiallyUsedImports
            .subtracting(["Foundation", "SwiftyBridges", "Vapor"])
            .sorted()
        let context: [String: Any] = [
            "apiDefinitions": apiDefinitions,
            "clientStructTemplates": clientStructTemplates,
            "protocolConformanceExtensions": protocolConformanceExtensions,
            "conditionalImports": conditionalImports,
            "serverCodeWarnings": serverCodeWarnings,
        ]
        let loader: FileSystemLoader
        if
            let resourceURL = Bundle.main.resourceURL,
            FileManager.default.fileExists(atPath: resourceURL.appendingPathComponent("Templates").path)
        {
            // We are running via Mint
            loader = FileSystemLoader(paths: [Path(resourceURL.path)])
        }
        else if let resourcePath = Bundle.module.resourcePath
        {
            loader = FileSystemLoader(paths: [Path(resourcePath)])
        }
        else
        {
            loader = FileSystemLoader(bundle: [Bundle.module])
        }
        let environment = Environment(loader: loader)
        
        let serverSource = try environment.renderTemplate(name: "Templates/ServerTemplate.swift.stencil", context: context)
        let serverFileURL = URL(fileURLWithPath: serverOutputFile)
        try FileManager.default.createDirectory(at: serverFileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(serverSource.utf8)
            .write(to: serverFileURL)
        
        let clientSource = try environment.renderTemplate(name: "Templates/ClientTemplate.swift.stencil", context: context)
        let clientFileURL = URL(fileURLWithPath: clientOutputFile)
        try FileManager.default.createDirectory(at: clientFileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(clientSource.utf8)
            .write(to: clientFileURL)
    }
}
