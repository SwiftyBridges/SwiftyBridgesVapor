import SwiftSyntax
import Foundation

final class Analysis: SyntaxVisitor {
    
    private let sourceDirectory: String
    private let verbose: Bool
    
    var apiDeclarations: [APIDeclaration] = []
    private var currentDeclaration: APIDeclaration?
    
    init(sourceDirectory: String, verbose: Bool) {
        self.sourceDirectory = sourceDirectory
        self.verbose = verbose
    }
    
    func run() {
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
        if verbose {
            print("Analyze: \(path.relativePath)")
        }
        let sourceFile = try SyntaxParser.parse(path)
        self.walk(sourceFile)
    }
    
    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        guard isAPIDefinition(node) else {
            return .skipChildren
        }
        
        guard currentDeclaration == nil else {
            fatalError("Nested API definitions are not supported.")
        }
        
        let leadingTrivia = String(node.description.utf8.prefix(node.leadingTriviaLength.utf8Length))?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        currentDeclaration = APIDeclaration(name: node.identifier.text, leadingTrivia: leadingTrivia ?? "", structSyntax: node)
        
        return .visitChildren
    }
    
    override func visitPost(_ node: StructDeclSyntax) {
        guard
            let currentDeclaration = currentDeclaration,
            node == currentDeclaration.structSyntax
        else {
            return
        }

        if currentDeclaration.publicMethods.isEmpty {
            print("WARNING: The type \(currentDeclaration.name) seems to have no public methods. No API methods will be generated in the client code.")
        }
        
        apiDeclarations.append(currentDeclaration)
        self.currentDeclaration = nil
    }
    
    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        guard
            var currentDeclaration = currentDeclaration,
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
        
        guard node.signature.asyncOrReasyncKeyword == nil else {
            // Async methods are not yet supported
            return .skipChildren
        }
        
        let returnType = self.returnType(of: node)
        
        let isInlinable = self.isInlinable(node)
        
        let parameters = node.signature.input.parameterList.map(MethodDeclaration.Parameter.init)
        
        let methodDeclaration = MethodDeclaration(
            name: node.identifier.text,
            leadingTrivia: leadingTrivia ?? "",
            isInlinable: isInlinable,
            parameters: parameters,
            mayThrow: mayThrow,
            returnType: returnType
        )
        
        currentDeclaration.publicMethods.append(methodDeclaration)
        self.currentDeclaration = currentDeclaration
        
        return .skipChildren
    }
    
    private func isAPIDefinition(_ node: StructDeclSyntax) -> Bool {
        guard let inheritedTypeCollection = node.inheritanceClause?.inheritedTypeCollection else {
            return false
        }
        return inheritedTypeCollection.contains { typeSyntax in
            typeSyntax.typeName.firstToken?.text == "APIDefinition"
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
    
    private func isVoid(_ typeSyntax: SimpleTypeIdentifierSyntax) -> Bool {
        if typeSyntax.withoutTrivia().name.description == "Void" {
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
    
    private func returnType(of node: FunctionDeclSyntax) -> MethodDeclaration.ReturnType {
        if let type = node.signature.output?.returnType {
            if let simpleSyntax = type.as(SimpleTypeIdentifierSyntax.self) {
                if simpleSyntax.name.description == "EventLoopFuture" {
                    guard let valueType = simpleSyntax.genericArgumentClause?.arguments.first?.argumentType else {
                        
                        fatalError("Could not parse return type of function \(node.signature.description)")
                    }
                    
                    if isVoid(valueType) {
                        return .voidEventLoopFuture
                    } else {
                        return .codableEventLoopFuture(valueTypeName: valueType.description)
                    }
                } else if isVoid(simpleSyntax) {
                    return .void
                } else {
                    return .codable(typeName: simpleSyntax.withoutTrivia().description)
                }
            } else {
                if isVoid(type) {
                    return .void
                } else {
                    fatalError("Could not parse return type of function \(node.signature.description)")
                }
            }
        } else {
            return .void
        }
    }
}
