//
//  APIDefinition.swift
//  APIDefinition
//
//  Created by Stephen Kockentiedt on 15.09.21.
//

import Vapor

public protocol APIDefinition {
    init(request: Request) throws
    static var middlewares: [Middleware] { get }
    static var remotelyCallableMethods: [AnyAPIMethod<Self>] { get }
}

public extension APIDefinition {
    static var middlewares: [Middleware] {
        []
    }
    
    static var remotelyCallableMethods: [AnyAPIMethod<Self>] {
        []
    }
}
