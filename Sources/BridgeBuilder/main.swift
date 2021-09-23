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
    var serverOutput: String = "ServerGenerated.swift"
    
    @Option(help: "Generated target Swift file for the client")
    var clientOutput: String = "ClientGenerated.swift"
    
    mutating func run() throws {
        let analysis = Analysis(sourceDirectory: sourceDirectory)
        analysis.run()
        
        let generator = Generator(apiDefinitions: analysis.apiDefinitions, serverOutputFile: serverOutput, clientOutputFile: clientOutput)
        try generator.run()
        
        print("Generated server code was written to '\(serverOutput)'.")
        print("Generated client code was written to '\(clientOutput)'.")
        print("Please add the source files to the corresponding app.")
    }
}

BridgeBuilder.main()
