//
//  APIRegistration.swift
//  APIRegistration
//
//  Created by Stephen Kockentiedt on 16.09.21.
//

import Foundation
import Vapor

/// Contains the calling logic of a specific registered API definition type
struct APIRegistration<API: APIDefinition> {
    private let methodByID: [APIMethodID: AnyAPIMethod<API>]
    
    init() {
        let idsAndMethods = API.remotelyCallableMethods
            .map { ($0.methodID, $0) }
        methodByID = .init(idsAndMethods, uniquingKeysWith: { first, _ in first })
    }
}

extension APIRegistration: AsyncResponder {
    /// Handles an API method call request for `API` from start to finish
    ///
    /// * Applies the correct middlewares
    /// * Decodes the method ID and parameters from `request`
    /// * Calls the API method
    /// * Encodes the return value or the thrown error as a `Response`
    ///
    /// - Parameter request: The method call request
    /// - Returns: The result of the method call as a `Response`
    func respond(to request: Request) async throws -> Response {
        guard let methodID = request.headers["API-Method"].first else {
            throw Abort(.badRequest)
        }
        
        guard let method = methodByID[APIMethodID(rawValue: methodID)] else {
            print("WARNING: API method call '\(methodID)' was not found. Please make sure that you have added the generated source code to the server app.")
            throw Abort(.badRequest, reason: "API method call '\(methodID)' was not found")
        }
        
        let methodCallResponder = MethodCallResponder(method: method)
        let completeResponder = API.middlewares.makeResponder(chainingTo: methodCallResponder)
        return try await completeResponder.respond(to: request).get()
    }
}

/// Allows an `AnyAPIMethod` to be embedded inside middlewares.
struct MethodCallResponder<API: APIDefinition> {
    var method: AnyAPIMethod<API>
}

extension MethodCallResponder: AsyncResponder {
    func respond(to request: Request) async throws -> Response {
        let api = try await API(request: request)
        let methodCall = try await method.decodeCall(from: request)
        return try await methodCall(api)
    }
}
