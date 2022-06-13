import Foundation
import SwiftSyntax
import SwiftSyntaxParser

/// Parses API definitions in the Swift files in the given source directory.
final class Analysis: SyntaxVisitor {
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
 
    /// The path to a directory containing the Swift files to be parsed
    private let sourceDirectory: String

    /// The names of the imports in the file currently analyzed
    private var importsOfCurrentFile: Set<String> = []
    
    /// The definition being currently parsed
    private var currentDefinition: APIDefinition?
    
    /// The type conforming to `GenerateClientStruct` being currently parsed
    private var currentClientStructTemplate: ClientStructTemplate?
    
    /// The path of the file currently analyzed
    private var currentFilePath = ""
    
    /// The converter needed to get the line number of definitions
    private var sourceLocationConverter = SourceLocationConverter(file: "", source: "")
    
    /// Default initializer
    /// - Parameter sourceDirectory: The path to a directory containing the Swift files to be parsed
    init(sourceDirectory: String) {
        self.sourceDirectory = sourceDirectory
    }
    
    /// Performs the parsing
    func run() {
        apiDefinitions = []
        let enumerator = FileManager.default.enumerator(atPath: sourceDirectory)
        while let path = enumerator?.nextObject() as? String {
            guard path.hasSuffix(".swift") else {
                continue
            }
            
            let relativeURL = URL(fileURLWithPath: path, relativeTo: URL(fileURLWithPath: sourceDirectory))
            let url = relativeURL.absoluteURL
            do {
                try analyze(file: url)
            } catch {
                fatalError("ERROR: Failed analysis of [\(url)]: \(error)")
            }
        }
    }
    
    func analyze(file path: URL) throws {
        let sourceFile = try SyntaxParser.parse(path)
        self.importsOfCurrentFile = []
        let filePath = path.standardized.absoluteURL.path
        self.currentFilePath = filePath
        self.sourceLocationConverter = .init(file: filePath, tree: sourceFile)
        self.walk(sourceFile)
    }

    override func visit(_ node: ImportDeclSyntax) -> SyntaxVisitorContinueKind {
        let importName: String
        if node.importKind == nil {
            importName = node.path.withoutTrivia().description
        } else {
            importName = node.path.removingLast().withoutTrivia().description.trimmingCharacters(in: .init(charactersIn: "."))
        }

        self.importsOfCurrentFile.insert(importName)
        
        return .skipChildren
    }
    
    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        if node.hasCopyToClientAnnotation {
            self.definitionsToCopyToClient.append(node.description)
            return .skipChildren
        }
        
        if node.inherits(fromAnyOf: "GenerateEquatable", "SwiftyBridges.GenerateEquatable") {
            protocolConformanceExtensions.append(.init(typeName: node.identifier.text, protocolName: "Equatable"))
        }
        
        if node.inherits(fromAnyOf: "GenerateHashable", "SwiftyBridges.GenerateHashable") {
            protocolConformanceExtensions.append(.init(typeName: node.identifier.text, protocolName: "Hashable"))
        }
        
        if node.inherits(fromAnyOf: "APIDefinition", "SwiftyBridges.APIDefinition") {
            guard
                currentDefinition == nil,
                currentClientStructTemplate == nil
            else {
                fatalError("Nested API definitions are not supported.")
            }
            
            let leadingTrivia = String(node.description.utf8.prefix(node.leadingTriviaLength.utf8Length))?.trimmingCharacters(in: .whitespacesAndNewlines)
            
            currentDefinition = APIDefinition(name: node.identifier.text, leadingTrivia: leadingTrivia ?? "", structSyntax: node)
            
            return .visitChildren
        } else if node.inherits(fromAnyOf: "GenerateClientStruct", "SwiftyBridges.GenerateClientStruct") {
            guard
                currentDefinition == nil,
                currentClientStructTemplate == nil
            else {
                fatalError("Nested types comforming to 'GenerateClientStruct' are not supported.")
            }
            
            let leadingTrivia = String(node.description.utf8.prefix(node.leadingTriviaLength.utf8Length))?.trimmingCharacters(in: .whitespacesAndNewlines)
            
            currentClientStructTemplate = ClientStructTemplate(
                name: node.identifier.text,
                leadingTrivia: leadingTrivia ?? "",
                isFluentModel: false, // Fluent models need to be classes
                classOrStructSyntax: node
            )
            
            return .visitChildren
        } else {
            return .skipChildren
        }
    }
    
    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        if node.hasCopyToClientAnnotation {
            self.definitionsToCopyToClient.append(node.description)
            return .skipChildren
        }
        
        if node.inherits(fromAnyOf: "GenerateEquatable", "SwiftyBridges.GenerateEquatable") {
            protocolConformanceExtensions.append(.init(typeName: node.identifier.text, protocolName: "Equatable"))
        }
        
        if node.inherits(fromAnyOf: "GenerateHashable", "SwiftyBridges.GenerateHashable") {
            protocolConformanceExtensions.append(.init(typeName: node.identifier.text, protocolName: "Hashable"))
        }
        
        guard node.inherits(fromAnyOf: "GenerateClientStruct", "SwiftyBridges.GenerateClientStruct") else {
            return .skipChildren
        }
        
        guard
            currentDefinition == nil,
            currentClientStructTemplate == nil
        else {
            fatalError("Nested types comforming to 'GenerateClientStruct' are not supported.")
        }
        
        let leadingTrivia = String(node.description.utf8.prefix(node.leadingTriviaLength.utf8Length))?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        currentClientStructTemplate = ClientStructTemplate(
            name: node.identifier.text,
            leadingTrivia: leadingTrivia ?? "",
            isFluentModel: node.inherits(from: "Model") || node.inherits(from: "Fluent.Model"),
            classOrStructSyntax: node
        )
        
        return .visitChildren
    }
    
    override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
        if node.hasCopyToClientAnnotation {
            self.definitionsToCopyToClient.append(node.description)
        }
        return .skipChildren
    }
    
    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        if node.hasCopyToClientAnnotation {
            self.definitionsToCopyToClient.append(node.description)
        }
        return .skipChildren
    }
    
    override func visitPost(_ node: StructDeclSyntax) {
        if
            let currentDefinition = currentDefinition,
            node == currentDefinition.structSyntax
        {
            if currentDefinition.publicMethods.isEmpty {
                print("WARNING: The type \(currentDefinition.name) seems to have no public methods. No API methods will be generated in the client code.")
            }
            
            apiDefinitions.append(currentDefinition)
            self.currentDefinition = nil
            self.potentiallyUsedImports.formUnion(self.importsOfCurrentFile)
        }
        else if
            let currentClientStructTemplate = currentClientStructTemplate,
            node == (currentClientStructTemplate.classOrStructSyntax as? StructDeclSyntax)
        {
            clientStructTemplates.append(currentClientStructTemplate)
            self.currentClientStructTemplate = nil
            self.potentiallyUsedImports.formUnion(self.importsOfCurrentFile)
        }
    }
    
    override func visitPost(_ node: ClassDeclSyntax) {
        if
            let currentClientStructTemplate = currentClientStructTemplate,
            node == (currentClientStructTemplate.classOrStructSyntax as? ClassDeclSyntax)
        {
            clientStructTemplates.append(currentClientStructTemplate)
            self.currentClientStructTemplate = nil
            self.potentiallyUsedImports.formUnion(self.importsOfCurrentFile)
        }
    }
    
    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        guard currentClientStructTemplate != nil else {
            return .skipChildren
        }
        
        if
            let modifiers = node.modifiers,
            modifiers.contains(where: { $0.name.text == "static" })
        {
            // We only want instance properties
            return .skipChildren
        }
        
        guard node.bindings.first?.accessor == nil else {
            // This is a computed property. We only want stored properties.
            return .skipChildren
        }
        
        guard let binding = node.bindings.first else {
            return .skipChildren
        }
        
        let bindingString = binding.description
        let propertyName = binding.pattern.description
        let typeName = binding.typeAnnotation?.type.description
        
        let leadingTrivia = String(node.description.utf8.prefix(node.leadingTriviaLength.utf8Length))?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let customAttributes = node.attributes?.compactMap { $0.as(CustomAttributeSyntax.self) }
            .map(CustomVarAttribute.init) ?? []
        
        let property = InstanceProperty(name: propertyName, type: typeName, binding: bindingString, leadingTrivia: leadingTrivia ?? "", customAttributes: customAttributes, bindingSyntax: binding)
        self.currentClientStructTemplate?.instanceProperties.append(property)

        return .skipChildren
    }
    
    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        guard
            var currentDeclaration = currentDefinition,
            node.isPublic
        else {
            return .skipChildren
        }
        
        let leadingTrivia = String(node.description.utf8.prefix(node.leadingTriviaLength.utf8Length))?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let mayThrow: Bool
        switch node.signature.throwsOrRethrowsKeyword?.tokenKind {
        case .throwsKeyword, .rethrowsKeyword:
            mayThrow = true
        default:
            mayThrow = false
        }
        
        let isAsync = node.signature.asyncOrReasyncKeyword?.text == "async"
        
        let returnType = self.returnType(of: node)
        
        let parameters = node.signature.input.parameterList.map(MethodDefinition.Parameter.init)
        
        let functionNameSourceRange = node.identifier.sourceRange(converter: sourceLocationConverter)
        
        let methodDefinition = MethodDefinition(
            name: node.identifier.text,
            leadingTrivia: leadingTrivia ?? "",
            isInlinable: node.isInlinable,
            parameters: parameters,
            isAsync: isAsync,
            mayThrow: mayThrow,
            returnType: returnType,
            filePath: currentFilePath,
            lineNumber: functionNameSourceRange.start.line ?? 1
        )
        
        currentDeclaration.publicMethods.append(methodDefinition)
        self.currentDefinition = currentDeclaration
        
        return .skipChildren
    }
    
    private func returnType(of node: FunctionDeclSyntax) -> MethodDefinition.ReturnType {
        if let type = node.signature.output?.returnType {
            if type.isVoid {
                return .void
            } else {
                return .codable(typeName: type.withoutTrivia().description)
            }
        } else {
            return .void
        }
    }
}

extension DeclSyntaxProtocol {
    /// Returns true if the declaration has a leading comment ` // bridge: copyToClient`
    var hasCopyToClientAnnotation: Bool {
        let docLines = self.leadingTrivia?.compactMap { piece -> String? in
            switch piece {
            case .lineComment(let line):
                return line.trimmingCharacters(in: .whitespacesAndNewlines)
            default:
                return nil
            }
        } ?? []
        for line in docLines {
            let lineWithoutSlashes = line.dropFirst(2)
            let parts = lineWithoutSlashes.components(separatedBy: ":")
            guard
                parts.count == 2,
                parts[0].trimmingCharacters(in: .whitespaces).lowercased() == "bridge",
                parts[1].trimmingCharacters(in: .whitespaces) == "copyToClient"
            else { continue }
            return true
        }
        return false
    }
}

extension ClassDeclSyntax {
    func inherits(from typeName: String) -> Bool {
        self.inheritanceClause?.inheritedTypeCollection.contains(where: { syntax in
            syntax.typeName.withoutTrivia().description == typeName
        }) ?? false
    }
    
    func inherits(fromAnyOf typeNames: String...) -> Bool {
        typeNames
            .lazy
            .map { self.inherits(from: $0) }
            .contains(true)
    }
}

extension FunctionDeclSyntax {
    var isInlinable: Bool {
        self.attributes?.compactMap { $0.as(AttributeSyntax.self) }
        .contains { $0.attributeName.withoutTrivia().description == "inlinable" }
        ?? false
    }
    
    var isPublic: Bool {
        self.modifiers?.contains { $0.name.text == "public" } ?? false
    }
}

extension StructDeclSyntax {
    func inherits(from typeName: String) -> Bool {
        self.inheritanceClause?.inheritedTypeCollection.contains(where: { syntax in
            syntax.typeName.withoutTrivia().description == typeName
        }) ?? false
    }
    
    func inherits(fromAnyOf typeNames: String...) -> Bool {
        typeNames
            .lazy
            .map { self.inherits(from: $0) }
            .contains(true)
    }
}

extension TypeSyntax {
    var isVoid: Bool {
        if
            let tupleSyntax = self.as(TupleTypeSyntax.self),
            tupleSyntax.elements.count == 0
        {
            return true
        } else if self.withoutTrivia().description == "Void" {
            return true
        } else {
            return false
        }
    }
}

extension VariableDeclSyntax {
    func hasAttribute(named attributeName: String) -> Bool {
        self.attributes?.contains(where: { syntax in
            syntax.as(CustomAttributeSyntax.self)?.attributeName.description == attributeName
        }) ?? false
    }
}
