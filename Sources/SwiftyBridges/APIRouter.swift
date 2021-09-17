//
//  APIRouter.swift
//  APIRouter
//
//  Created by Stephen Kockentiedt on 16.09.21.
//

import Foundation
import Vapor

public class APIRouter {
    private var registrationByTypeName: [String: Responder] = [:]
    
    public init() {}
}


// MARK: - Public Members

extension APIRouter {
    public func register<API: APIDefinition>(_ api: API.Type) {
        let typeName = String(describing: API.self)
        let registration = APIRegistration<API>()
        registrationByTypeName[typeName] = registration
    }
    
    public func handle(_ request: Request) -> EventLoopFuture<Response> {
        guard
            let apiTypeName = request.headers["API-Type"].first,
            let registration = registrationByTypeName[apiTypeName]
        else {
            return request.eventLoop.makeFailedFuture(Abort(.badRequest))
        }
        
        return registration.respond(to: request)
    }
}
