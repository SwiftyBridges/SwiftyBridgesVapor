import Foundation
import PackagePlugin

private let startBoldText = "\u{001B}[0;1m"
private let startGreenBoldText = "\u{001B}[0;1;38;5;10m"
private let startRedBoldText = "\u{001B}[0;1;31m"
private let resetTextFormatting = "\u{001B}[0m"

@main struct APICodeGenerator: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        let builder = try context.tool(named: "BridgeBuilder")
        let workDirectory = context.pluginWorkDirectory
        let serverOutputFile = workDirectory
            .appending("GeneratedServerCode")
            .appending("GeneratedServerCode.swift")
        let clientCodeDirectory = workDirectory.appending("GeneratedClientCode")
        let clientOutputFile = clientCodeDirectory.appending("GeneratedAPIClientCode.swift")
        let clientCodeDirectoryName = "GeneratedClientCode/\(target.name)"
        let symlinkPath = context.package.directory.appending(subpath: clientCodeDirectoryName).string
        
        // Using this plugin only makes sense for targets containing source code:
        let target = target as! SourceModuleTarget
        
        let linkSuccessMessage =
        """
        \(startGreenBoldText)[ NOTICE ]\(startBoldText) SwiftyBridges has created a directory for the generated API client code of the target '\(target.name)' at '\(clientCodeDirectoryName)' in the package directory\(resetTextFormatting)
        """
        
        // The --disable-sandbox flag gives us write permission for the package directory so that we can create a symlink to the generated client code:
        let linkFailureMessage =
        """
        \(startRedBoldText)[ WARNING ]\(startBoldText) SwiftyBridges could not create a linked directory for the generated API client code. Please run the following command in the package directory to create it:
            
        swift package clean && swift build --disable-sandbox
        \(resetTextFormatting)
        """
        
        return [
            .buildCommand(
                displayName: "BridgeBuilder",
                executable: builder.path,
                arguments: [
                    target.directory,
                    "--server-output", serverOutputFile,
                    "--client-output", clientOutputFile,
                    "--quiet", // Silence the normal output of BridgeBuilder
                    "--link-path", symlinkPath, // Create a symlink to the generated client code here
                    "--link-destination-path", clientCodeDirectory.string, // The symlink shall point here
                    "--link-success-message", linkSuccessMessage, // Show this message if the symlink has been newly created
                    "--link-permission-failure-message", linkFailureMessage, // Show this message if the symlink could not be created because we didn't have write permission
                ],
                environment: [:],
                inputFiles: target.sourceFiles(withSuffix: ".swift").map { $0.path }, // All Swift files in the target
                outputFiles: [
                    serverOutputFile, // The generated server code shall be compiled together with the target code. The generated client code MUST NOT be compiled into the target. That's why it is missing here.
                ]
            ),
        ]
    }
}
