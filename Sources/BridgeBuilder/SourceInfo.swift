import Foundation

/// Holds information about the parsed source code used to generate the server and client API code
struct SourceInfo {
    /// Contains the names of all imports used in any file containing an API definition
    var potentiallyUsedImports: Set<String> = []

    /// Contains infos about the found API definitions after `run()` has finished
    var apiDefinitions: [APIDefinition] = []
    
    /// Contains infos about the found types conforming to `GenerateClientStruct` after `run()` has finished
    var clientStructTemplates: [ClientStructTemplate] = []
    
    /// Contains a list of extensions that shall be generated to signal protocol conformance
    var protocolConformanceExtensions: [ProtocolConformance] = []
    
    /// Contains a list of definitions that shall be emitted directly into the client code
    var definitionsToCopyToClient: [String] = []
}

// MARK: - Public Members

extension SourceInfo {
    /// The modules that shall be imported by the generated code if possible
    var conditionalImports: [String] {
        potentiallyUsedImports
            .subtracting(["Foundation", "SwiftyBridges", "Vapor"])
            .sorted()
    }
    
    var stencilContext: [String: Any] {
        [
            "apiDefinitions": apiDefinitions,
            "clientStructTemplates": clientStructTemplates,
            "protocolConformanceExtensions": protocolConformanceExtensions,
            "definitionsToCopyToClient": definitionsToCopyToClient,
            "conditionalImports": conditionalImports,
        ]
    }
}
