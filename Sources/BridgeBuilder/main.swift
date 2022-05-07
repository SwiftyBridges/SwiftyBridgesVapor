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
    
    @Argument(help: "Directory containing the API definitions")
    var sourceDirectory: String
    
    @Option(help: "Generated target Swift file for the server")
    var serverOutput: String = "ServerGenerated.swift"
    
    @Option(help: "Generated target Swift file for the client")
    var clientOutput: String = "ClientGenerated.swift"
    
    @Flag(name: [.short, .long], help: "Reduce the output of the command")
    var quiet: Bool = false
    
    /// If this option and `linkDestinationPath` are set, the command tries to create a relative symbolic link at this path
    @Option(help: .hidden)
    var linkPath: String?
    
    /// If this option and `linkPath` are set, the command tries to create a relative symbolic link pointing to this destination
    @Option(help: .hidden)
    var linkDestinationPath: String?
    
    /// If the creation of the symbolic link is successful, this message will be printed to the output
    @Option(help: .hidden)
    var linkSuccessMessage: String?
    
    /// If the creation of the symbolic link fails because of missing permissions, this message will be printed to the output
    @Option(help: .hidden)
    var linkPermissionFailureMessage: String?
    
    /// Warnings to include into the generated server code. Precent encoding is removed from these strings before adding them to the source.
    @Option(name: .customLong("warning"), parsing: .singleValue, help: .hidden)
    var warnings: [String] = []
    
    mutating func run() throws {
        let analysis = Analysis(sourceDirectory: sourceDirectory)
        analysis.run()
        
        let generator = Generator(
            potentiallyUsedImports: analysis.potentiallyUsedImports,
            apiDefinitions: analysis.apiDefinitions,
            serverCodeWarnings: warnings.compactMap { $0.removingPercentEncoding },
            serverOutputFile: serverOutput,
            clientOutputFile: clientOutput
        )
        try generator.run()
        
        if !quiet {
            print("Generated server code was written to '\(serverOutput)'.")
            print("Generated client code was written to '\(clientOutput)'.")
            print("Please add the source files to the corresponding app.")
        }
        
        if
            let linkPath = linkPath,
            let linkDestinationPath = linkDestinationPath
        {
            SymbolicLinkCreator.tryToCreateSymbolicLink(
                atPath: linkPath,
                toDestinationPath: linkDestinationPath,
                successMessage: linkSuccessMessage,
                permissionFailureMessage: linkPermissionFailureMessage
            )
        }
    }
}

BridgeBuilder.main()
