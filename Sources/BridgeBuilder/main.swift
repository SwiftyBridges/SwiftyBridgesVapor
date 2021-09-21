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
    
    mutating func run() throws {
        let analysis = Analysis(sourceDirectory: sourceDirectory)
        analysis.run()
        
        let generator = Generator(apiDefinitions: analysis.apiDefinitions, serverOutputFile: serverOutput, clientOutputFile: clientOutput)
        try generator.run()
    }
}

BridgeBuilder.main()
