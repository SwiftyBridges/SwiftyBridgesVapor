import Foundation
import PackagePlugin

@main struct APICodeGenerator: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        let builder = try context.tool(named: "BridgeBuilder")
        let outputDirectory = context.pluginWorkDirectory.appending("GeneratedSources")
        let serverOutputFile = outputDirectory.appending("server.swift")
        let clientOutputFile = outputDirectory.appending("client.swift")
        
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
