import Foundation
import PackagePlugin

private let startBoldText = "\u{001B}[0;1m"
private let startGreenBoldText = "\u{001B}[0;1;38;5;10m"
private let startRedBoldText = "\u{001B}[0;1;31m"
private let resetTextFormatting = "\u{001B}[0m"

/// This plugin can be used for targets containing `APIDefinition`s to automatically generate both server as well as client API code with every build.
///
/// The generated server code is then automatically compiled together with the other server code. The generated client code can be made accessible by once calling the following command inside the package directory in the terminal. This creates a symlink to the folder where the client code is generated:
/// ```
/// swift package clean && swift build --disable-sandbox
/// ```
///
/// If Xcode shall be used to compile or run the server code, an Xcode post-build script is needed to surface the generated API client code because it is generated outside the package folder. Add the following script as a post-build script to the main scheme of your package in Xcode and be sure to select the 'App' target under 'Provide build settings from':
/// ```
/// # This script is needed to ensure that the API client code generated by SwiftyBridges is updated and made accessible each time the server code is updated and built. After building, you can find it under 'GeneratedClientCode' inside the package directory.
/// cd "$WORKSPACE_PATH"
/// swift package --disable-sandbox xcode-bridge-helper
/// ```
/// Also consider making the scheme shared and committing it to git (it is located under .swiftpm/xcode in the package folder) so that the script is already configured for other people or when freshly cloning the project.
///
@main struct APICodeGenerator: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        let builder = try context.tool(named: "BridgeBuilder")
        let workDirectory = context.pluginWorkDirectory
        let serverOutputFile = workDirectory
            .appending("GeneratedServerCode")
            .appending("GeneratedServerCode.swift")
        let clientCodeDirectory = workDirectory.appending(Constants.generatedClientCodeSubfolderName)
        let clientOutputFile = clientCodeDirectory.appending("GeneratedAPIClientCode.swift")
        let clientCodeDirectoryName = Constants.packageFolderClientCodeSubfolder(forTargetName: target.name)
        let symlinkPath = context.package.directory.appending(subpath: clientCodeDirectoryName).string
        
        // Using this plugin only makes sense for targets containing source code:
        let target = target as! SourceModuleTarget
        
        let linkSuccessMessage =
        """
        \(startGreenBoldText)[ NOTICE ]\(startBoldText) SwiftyBridges has created a directory for the generated API client code of the target '\(target.name)' at '\(clientCodeDirectoryName)' in the package directory\(resetTextFormatting)
        """
        
        var arguments: [CustomStringConvertible] = [
            target.directory,
            "--server-output", serverOutputFile,
            "--client-output", clientOutputFile,
            "--quiet", // Silence the normal output of BridgeBuilder
            "--link-path", symlinkPath, // Create a symlink to the generated client code here
            "--link-destination-path", clientCodeDirectory.string, // The symlink shall point here
            "--link-success-message", linkSuccessMessage, // Show this message if the symlink has been newly created
        ]
        
        if ProcessInfo.processInfo.environment["__CFBundleIdentifier"] == "com.apple.dt.Xcode" {
            // The current build is performed using Xcode
            
            let schemeContainingPathURL = URL(fileURLWithPath: context.package.directory.appending(subpath: ".swiftpm/xcode/").string)
            let fileEnumerator = FileManager.default.enumerator(at: schemeContainingPathURL, includingPropertiesForKeys: nil, options: [.skipsPackageDescendants])
            let schemeFileURLs = (fileEnumerator?.allObjects ?? [])
                .compactMap { $0 as? URL }
                .filter { $0.pathExtension == "xcscheme" }
            
            var xcodeBridgeHelperIsUsed = false
            for schemeURL in schemeFileURLs {
                guard
                    let data = try? Data(contentsOf: schemeURL),
                    let contents = String(data: data, encoding: .utf8)
                else { continue }
                
                if contents.contains("swift package --disable-sandbox xcode-bridge-helper") {
                    xcodeBridgeHelperIsUsed = true
                    break
                }
            }
            
            if !xcodeBridgeHelperIsUsed {
                arguments += [
                    "--warning", """
                        IMPORTANT: An Xcode post-build script is needed to surface the API client code generated by SwiftyBridges because it is generated outside the package folder. Add the following script as a post-build script to the main scheme of your package in Xcode and be sure to select the 'App' target under 'Provide build settings from':
                        
                        
                        # This script is needed to ensure that the API client code generated by SwiftyBridges is updated and made accessible each time the server code is updated and built. After building, you can find it under 'GeneratedClientCode' inside the package directory.
                        cd "$WORKSPACE_PATH"
                        swift package --disable-sandbox xcode-bridge-helper
                        
                        
                        Also consider making the scheme shared and committing it to git (it is located under .swiftpm/xcode in the package folder) so that the script is already configured for other people or when freshly cloning the project.
                        
                        This warning may persist after adding the post-build script until another file has been added to the package or the DerivedData folder has been deleted.
                        """.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
                ]
            }
        } else {
            // The --disable-sandbox flag gives us write permission for the package directory so that we can create a symlink to the generated client code:
            let linkFailureMessage =
            """
            \(startRedBoldText)[ WARNING ]\(startBoldText) SwiftyBridges could not create a linked directory for the generated API client code. Please run the following command in the package directory to create it:
                
            swift package clean && swift build --disable-sandbox
            \(resetTextFormatting)
            """
            
            arguments += [
                "--link-permission-failure-message", linkFailureMessage, // Show this message if the symlink could not be created because we didn't have write permission
            ]
        }
        
        return [
            .buildCommand(
                displayName: "BridgeBuilder",
                executable: builder.path,
                arguments: arguments,
                environment: [:],
                inputFiles: target.sourceFiles(withSuffix: ".swift").map { $0.path }, // All Swift files in the target
                outputFiles: [
                    serverOutputFile, // The generated server code shall be compiled together with the target code. The generated client code MUST NOT be compiled into the target. That's why it is missing here.
                ]
            ),
        ]
    }
}
