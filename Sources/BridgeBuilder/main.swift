//
//  main.swift
//
//  Created by Stephen Kockentiedt on 15.09.21.
//

import ArgumentParser
import Foundation

struct BridgeBuilder: ParsableCommand {
    static var configuration: CommandConfiguration {
        CommandConfiguration(commandName:"swift run BridgeBuilder")
    }
    
    @Argument(help: "'Sources/' directory")
    var sourceDirectory: String
    
    @Option(help: "Generated target Swift file for the server")
    var serverOutput: String
    
    @Option(help: "Generated target Swift file for the client")
    var clientOutput: String
    
    @Flag(help: "Print verbose logs")
    var verbose: Bool = false
    
    mutating func run() throws {
        // Step 1: Analyze all files looking for `distributed actor` decls
        let analysis = Analysis(sourceDirectory: sourceDirectory, verbose: verbose)
        analysis.run()
        
        let generator = Generator(apiDeclarations: analysis.apiDeclarations, serverOutputFile: serverOutput, clientOutputFile: clientOutput)
        try generator.run()
    }
}

BridgeBuilder.main()
