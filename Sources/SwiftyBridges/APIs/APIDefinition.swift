//
//  APIDefinition.swift
//  APIDefinition
//
//  Created by Stephen Kockentiedt on 15.09.21.
//

import Vapor

/// Conform structs to this protocol to create APIs that can be called from client code. All `public` methods in the main definition will be callable from client code.
public protocol APIDefinition {
    /// For every method call by the client, a new instance of the API definition struct is created
    /// - Parameters:
    ///   - req: The request that was received for the API method call
    init(req: Request) async throws
    
    /// Optionally implement this property to determine the middlewares that shall be used for every API method call to this API definition
    ///
    /// The middlewares will be called in normal order for the request and then in reverse order for the response.
    static var middlewares: [Middleware] { get }
    
    /// DO NOT implement this property yourself. An implementation will be generated by SwiftyBridges.
    static var remotelyCallableMethods: [AnyAPIMethod<Self>] { get }
}

public extension APIDefinition {
    /// Default implementation of the protocol requirement. Uses no middleware.
    static var middlewares: [Middleware] {
        []
    }
    
    /// Default implementation to prevent compiler errors until the code generation has been run for the first time.
    static var remotelyCallableMethods: [AnyAPIMethod<Self>] {
        []
    }
}
