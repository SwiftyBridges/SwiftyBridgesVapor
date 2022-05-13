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
    
    /// The path to a directory containing the Swift files to be parsed
    private let sourceDirectory: String

    /// The names of the imports in the file currently analyzed
    private var importsOfCurrentFile: Set<String> = []
    
    /// The definition being currently parsed
    private var currentDefinition: APIDefinition?
    
    /// The type conforming to `GenerateClientStruct` being currently parsed
    private var currentClientStructTemplate: ClientStructTemplate?
    
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
        if isAPIDefinition(node) {
            guard
                currentDefinition == nil,
                currentClientStructTemplate == nil
            else {
                fatalError("Nested API definitions are not supported.")
            }
            
            let leadingTrivia = String(node.description.utf8.prefix(node.leadingTriviaLength.utf8Length))?.trimmingCharacters(in: .whitespacesAndNewlines)
            
            currentDefinition = APIDefinition(name: node.identifier.text, leadingTrivia: leadingTrivia ?? "", structSyntax: node)
            
            return .visitChildren
        } else if isClientStructTemplate(node) {
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
        guard isClientStructTemplate(node) else {
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
        guard let currentClientStructTemplate = currentClientStructTemplate else {
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
        
        var bindingString = binding.description
        
        let leadingTrivia = String(node.description.utf8.prefix(node.leadingTriviaLength.utf8Length))?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if node.hasAttribute(named: "Children")
            || node.hasAttribute(named: "Fluent.Children")
            || node.hasAttribute(named: "Siblings")
            || node.hasAttribute(named: "Fluent.Siblings")
        {
            // We need to make the type optional, because Fluent does not encode the attribute if it has not been fetched:
            bindingString += "?"
        }
        else if
            node.hasAttribute(named: "Parent")
                || node.hasAttribute(named: "Fluent.Parent")
                || node.hasAttribute(named: "OptionalParent")
                || node.hasAttribute(named: "Fluent.OptionalParent"),
            let type = binding.typeAnnotation?.type
        {
            let variableName = binding.pattern.description
            let typeString = type.description
            bindingString = "\(variableName): SwiftyBridgesClient.ParentReference<\(typeString)>"
        }
        
        let property = InstanceProperty(binding: bindingString, leadingTrivia: leadingTrivia ?? "")
        self.currentClientStructTemplate?.instanceProperties.append(property)

        return .skipChildren
    }
    
    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        guard
            var currentDeclaration = currentDefinition,
            isPublic(node)
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
        
        let isInlinable = self.isInlinable(node)
        
        let parameters = node.signature.input.parameterList.map(MethodDefinition.Parameter.init)
        
        let methodDeclaration = MethodDefinition(
            name: node.identifier.text,
            leadingTrivia: leadingTrivia ?? "",
            isInlinable: isInlinable,
            parameters: parameters,
            isAsync: isAsync,
            mayThrow: mayThrow,
            returnType: returnType
        )
        
        currentDeclaration.publicMethods.append(methodDeclaration)
        self.currentDefinition = currentDeclaration
        
        return .skipChildren
    }
    
    #warning("TODO: Make the next three extensions on the corresponsing nodes:")
    
    private func isAPIDefinition(_ node: StructDeclSyntax) -> Bool {
        guard let inheritedTypeCollection = node.inheritanceClause?.inheritedTypeCollection else {
            return false
        }
        return inheritedTypeCollection.contains { typeSyntax in
            typeSyntax.typeName.firstToken?.text == "APIDefinition"
        }
    }
    
    private func isClientStructTemplate(_ node: StructDeclSyntax) -> Bool {
        guard let inheritedTypeCollection = node.inheritanceClause?.inheritedTypeCollection else {
            return false
        }
        return inheritedTypeCollection.contains { typeSyntax in
            typeSyntax.typeName.firstToken?.text == "GenerateClientStruct"
        }
    }
    
    private func isClientStructTemplate(_ node: ClassDeclSyntax) -> Bool {
        guard let inheritedTypeCollection = node.inheritanceClause?.inheritedTypeCollection else {
            return false
        }
        return inheritedTypeCollection.contains { typeSyntax in
            typeSyntax.typeName.firstToken?.text == "GenerateClientStruct"
        }
    }
    
    private func isPublic(_ node: FunctionDeclSyntax) -> Bool {
        node.modifiers?.contains { $0.name.text == "public" } ?? false
    }
    
    private func isVoid(_ typeSyntax: TypeSyntax) -> Bool {
        if
            let tupleSyntax = typeSyntax.as(TupleTypeSyntax.self),
            tupleSyntax.elements.count == 0
        {
            return true
        } else if typeSyntax.withoutTrivia().description == "Void" {
            return true
        } else {
            return false
        }
    }
    
    private func isInlinable(_ function: FunctionDeclSyntax) -> Bool {
        function.attributes?.compactMap { $0.as(AttributeSyntax.self) }
        .contains { $0.attributeName.withoutTrivia().description == "inlinable" }
        ?? false
    }
    
    private func returnType(of node: FunctionDeclSyntax) -> MethodDefinition.ReturnType {
        if let type = node.signature.output?.returnType {
            if isVoid(type) {
                return .void
            } else {
                return .codable(typeName: type.withoutTrivia().description)
            }
        } else {
            return .void
        }
    }
}

extension ClassDeclSyntax {
    func inherits(from typeName: String) -> Bool {
        self.inheritanceClause?.inheritedTypeCollection.contains(where: { syntax in
            syntax.typeName.description == typeName
        }) ?? false
    }
}

extension VariableDeclSyntax {
    func hasAttribute(named attributeName: String) -> Bool {
        self.attributes?.contains(where: { syntax in
            syntax.as(CustomAttributeSyntax.self)?.attributeName.description == attributeName
        }) ?? false
    }
}
