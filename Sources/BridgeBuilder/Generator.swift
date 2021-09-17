//
//  Generator.swift
//  Generator
//
//  Created by Stephen Kockentiedt on 16.09.21.
//

import Foundation

class Generator {
    private let apiDeclarations: [APIDeclaration]
    private let serverOutputFile: String
    private let clientOutputFile: String
    
    init(apiDeclarations: [APIDeclaration], serverOutputFile: String, clientOutputFile: String) {
        self.apiDeclarations = apiDeclarations
        self.serverOutputFile = serverOutputFile
        self.clientOutputFile = clientOutputFile
    }
    
    func run() throws {
        let serverSource = self.serverSource()
        try Data(serverSource.utf8)
            .write(to: URL(fileURLWithPath: serverOutputFile))
        
        let clientSource = self.clientSource()
        
        try Data(clientSource.utf8)
            .write(to: URL(fileURLWithPath: clientOutputFile))
    }
}

// MARK: - Server Source Generation

private extension Generator {
    func serverSource() -> String {
        """
        import SwiftyBridges
        import Vapor
        
        \(
        apiDeclarations.map { self.serverSource(for: $0) }
        .joined(separator: "\n\n")
        )
        
        """
    }
    
    func serverSource(for apiType: APIDeclaration) -> String {
        """
        extension \(apiType.name) {
        \(
            remotelyCallableMethodsSource(for: apiType)
                .indented(toLevel: 1)
        )
            
        \(
        apiType.publicMethods.map { method in
            callTypeServerSource(for: method, in: apiType)
                .indented(toLevel: 1)
        }
        .joined(separator: "\n\n")
        )
        }
        """
    }
    
    func remotelyCallableMethodsSource(for apiType: APIDeclaration) -> String {
        """
        static let remotelyCallableMethods: [AnyAPIMethod<\(apiType.name)>] = [
        \(
        apiType.publicMethods.map { method in
            "AnyAPIMethod(method: \(method.generatedTypeName).self),"
        }
        .joined(separator: "\n")
        .indented(toLevel: 1)
        )
        ]
        """
    }
    
    func callTypeServerSource(for method: MethodDeclaration, in apiType: APIDeclaration) -> String {
        """
        private struct \(method.generatedTypeName): APIMethodCall {
            typealias API = \(apiType.name)
            typealias ReturnType = \(method.returnType.codableEffectiveReturnTypeName)
        
            static let methodID: APIMethodID = "\(method.methodID)"
                        
        \(
        method.parameters.enumerated().map { index, parameter in
            "var parameter\(index): \(parameter.typeName)"
        }
        .joined(separator: "\n")
        .indented(toLevel: 1)
        )
        
        \(
        callTypeCodingKeysSource(for: method)
        .indented(toLevel: 1)
        )
        
            func call(on api: API) throws -> EventLoopFuture<\(method.returnType.codableEffectiveReturnTypeName)> {
                \(method.returnType.isFuture ? "" : "api.request.eventLoop.future(")
                \(method.mayThrow ? "try " : "")api.\(method.name)(
        \(
        method.parameters.enumerated().map { index, parameter in
        "\(parameter.label.map { $0 + ": " } ?? "")parameter\(index)"
        }
        .joined(separator: ",\n")
        .indented(toLevel: 3)
        )
                )
                \(method.returnType.isFuture ? "" : ")")
                \(method.returnType.effectiveReturnTypeName == "Void" ? ".map { NoReturnValue() }" : "")
            }
        }
        """
    }
}

// MARK: - Client Source Generation

private extension Generator {
    func clientSource() -> String {
        """
        import Foundation
        import SwiftyBridgesClient
        
        \(
        apiDeclarations.map { self.clientSource(for: $0) }
        .joined(separator: "\n\n")
        )
        
        """
    }
    
    func clientSource(for apiType: APIDeclaration) -> String {
        """
        \(
        clientTypeSource(for: apiType)
        )
            
        \(
        clientTypeExtensionSource(for: apiType)
        )
        """
    }
    
    func clientTypeSource(for apiType: APIDeclaration) -> String {
        """
        \(apiType.leadingTrivia.reIndented(toLevel: 0))
        struct \(apiType.name): SwiftyBridgesClient.API {
            private let baseRequest: URLRequest
            private let client: BridgeClient
            
            init(baseRequest: URLRequest, client: BridgeClient = .shared) {
                self.baseRequest = baseRequest
                self.client = client
            }
        
        \(
        apiType.publicMethods.map { method in
        """
        \(method.leadingTrivia.reIndented(toLevel: 1))
            func \(method.name)(
        \(
        method.parameters.map { parameter in
            "        \(parameter.firstName ?? "")\(parameter.secondName.map { " " + $0 } ?? ""): \(parameter.typeName)"
        }
        .joined(separator: ",\n")
        )
            ) async throws -> \(method.returnType.effectiveReturnTypeName) {
                let call =
                \(method.generatedTypeName)(
        \(
        method.parameters.enumerated().map { index, parameter in
            "            parameter\(index): \(parameter.variableName)"
        }
        .joined(separator: ",\n")
        )
                )
                \(method.returnType.effectiveReturnTypeName == "Void" ? "_ = " : "return ")try await client.perform(call, baseRequest: baseRequest)
            }
        """
        }
        .joined(separator: "\n\n")
        )
        }
        """
    }
    
    func clientTypeExtensionSource(for apiType: APIDeclaration) -> String {
        """
        extension \(apiType.name) {
        \(
        apiType.publicMethods.map { method in
        """
            private struct \(method.generatedTypeName): APIMethodCall {
                typealias ReturnType = \(method.returnType.codableEffectiveReturnTypeName)
                    
                static let typeName = "\(apiType.name)"
                static let methodID = "\(method.methodID)"
                        
        \(
        method.parameters.enumerated().map { index, parameter in
            "        var parameter\(index): \(parameter.typeName)"
        }
        .joined(separator: "\n")
        )
                        
        \(
        callTypeCodingKeysSource(for: method)
        .indented(toLevel: 2)
        )
            }
        """
        }
        .joined(separator: "\n\n")
        )
        }
        """
    }
}

// MARK: - Common Source Generation

private extension Generator {
    func callTypeCodingKeysSource(for method: MethodDeclaration) -> String {
        guard method.parameters.count > 0 else {
            return ""
        }
        
        return """
        enum CodingKeys: String, CodingKey {
        \(
        method.parameters.enumerated().map { index, parameter in
            "case parameter\(index) = \"\(index)\(parameter.label.map { "_" + $0 } ?? "")\""
        }
        .joined(separator: "\n")
        .indented(toLevel: 1)
        )
        }
        """
    }
}

// MARK: - Helpers

extension MethodDeclaration {
    var methodID: String {
        let parameterPart = parameters.map { parameter -> String in
            "\(parameter.firstName.map { $0 + ": " } ?? "")\(parameter.typeName)"
        }
            .joined(separator: ", ")
        
        return "\(name)(\(parameterPart)) -> \(returnType.effectiveReturnTypeName)"
    }
    
    var generatedTypeName: String {
        let parameterPart = parameters.map { parameter -> String in
            let typeName = parameter.typeName
                .replacingOccurrences(of: ".", with: "_")
                .replacingOccurrences(of: "<", with: "_")
                .replacingOccurrences(of: ">", with: "_")
                .replacingOccurrences(of: ",", with: "_")
                .replacingOccurrences(of: " ", with: "")
            return "\(parameter.label ?? "")_\(typeName)"
        }
            .joined(separator: "_")
        
        return "Call_\(name)_\(parameterPart)"
    }
}

extension MethodDeclaration.ReturnType {
    var effectiveReturnTypeName: String {
        switch self {
        case .void, .voidEventLoopFuture:
            return "Void"
        case .codable(let typeName), .codableEventLoopFuture(let typeName):
            return typeName
        }
    }
    
    var codableEffectiveReturnTypeName: String {
        switch self {
        case .void, .voidEventLoopFuture:
            return "NoReturnValue"
        case .codable(let typeName), .codableEventLoopFuture(let typeName):
            return typeName
        }
    }
    
    var isFuture: Bool {
        switch self {
        case .void, .codable:
            return false
        case .voidEventLoopFuture, .codableEventLoopFuture:
            return true
        }
    }
}

extension MethodDeclaration.Parameter {
    var label: String? {
        if firstName == "_" {
            return nil
        }
        
        return firstName
    }
    
    var variableName: String {
        secondName ?? firstName ?? "_"
    }
}

private extension String {
    func indented(toLevel level: Int) -> String {
        guard level >= 1 else {
            return self
        }
        
        var copy = self
        for _ in 1...level {
            copy = "    " + copy.replacingOccurrences(of: "\n", with: "\n    ")
        }
        return copy
    }
    func reIndented(toLevel level: Int) -> String {
        self.split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .joined(separator: "\n")
            .indented(toLevel: level)
    }
}
