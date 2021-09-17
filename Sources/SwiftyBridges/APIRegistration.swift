//
//  File.swift
//  File
//
//  Created by Stephen Kockentiedt on 16.09.21.
//

import Foundation
import Vapor

struct APIRegistration<API: APIDefinition> {
    private let methodByID: [APIMethodID: AnyAPIMethod<API>]
    
    init() {
        let idsAndMethods = API.remotelyCallableMethods
            .map { ($0.methodID, $0) }
        methodByID = .init(idsAndMethods, uniquingKeysWith: { first, _ in first })
    }
}

extension APIRegistration: Responder {
    func respond(to request: Request) -> EventLoopFuture<Response> {
        guard
            let methodID = request.headers["API-Method"].first,
            let method = methodByID[APIMethodID(rawValue: methodID)]
        else {
            return request.eventLoop.makeFailedFuture(Abort(.badRequest))
        }
        
        let methodCallResponder = MethodCallResponder(method: method)
        let completeResponder = API.middlewares.makeResponder(chainingTo: methodCallResponder)
        return completeResponder.respond(to: request)
    }
}

struct MethodCallResponder<API: APIDefinition> {
    var method: AnyAPIMethod<API>
}

extension MethodCallResponder: Responder {
    func respond(to request: Request) -> EventLoopFuture<Response> {
        do {
            let api = try API(request: request)
            return method.decodeCall(from: request).flatMap { methodCall in
                do {
                    return try methodCall(api)
                } catch {
                    return request.eventLoop.makeFailedFuture(error)
                }
            }
        } catch {
            return request.eventLoop.makeFailedFuture(error)
        }
    }
}
