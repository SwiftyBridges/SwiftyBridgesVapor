import Foundation
import PackagePlugin

@main struct APICodeGenerator: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        let builder = try context.tool(named: "BridgeBuilder")
        let workDirectory = context.pluginWorkDirectory
        let serverOutputFile = workDirectory
            .appending("GeneratedServerCode")
            .appending("GeneratedServerCode.swift")
        let clientOutputFile = workDirectory
            .appending("GeneratedClientCode")
            .appending("GeneratedAPIClientCode.swift")
        
        let target = target as! SourceModuleTarget

        return [
            .buildCommand(
                displayName: "BridgeBuilder",
                executable: builder.path,
                arguments: [
                    target.directory,
                    "--server-output", serverOutputFile,
                    "--client-output", clientOutputFile,
                ],
                environment: [:],
                inputFiles: target.sourceFiles(withSuffix: ".swift").map { $0.path },
                outputFiles: [
                    serverOutputFile,
                ]
            ),
        ]
    }
}
