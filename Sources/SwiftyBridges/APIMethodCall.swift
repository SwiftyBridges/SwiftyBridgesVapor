//
//  APIMethodCall.swift
//  APIMethodCall
//
//  Created by Stephen Kockentiedt on 16.09.21.
//

import Foundation
import Vapor

public struct APIMethodID: Codable, Hashable {
    var rawValue: String
}

extension APIMethodID: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        rawValue = value
    }
}

public protocol APIMethodCall: Content {
    associatedtype API: APIDefinition
    associatedtype ReturnType: Codable
    static var methodID: APIMethodID { get }
    func call(on api: API) throws -> EventLoopFuture<ReturnType>
}

public struct NoReturnValue: Codable {
    public init() {}
    public init(from decoder: Decoder) throws {}
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(0)
    }
}

public struct AnyAPIMethod<API: APIDefinition> {
    typealias MethodCall = (API) throws -> EventLoopFuture<Response>
    
    let methodID: APIMethodID
    let decodeCallAction: (Request) -> EventLoopFuture<MethodCall>
    
    public init<MethodCallType: APIMethodCall>(method: MethodCallType.Type) where MethodCallType.API == API {
        methodID = method.methodID
        decodeCallAction = { (request: Request) -> EventLoopFuture<MethodCall> in
            return MethodCallType.decodeRequest(request).map { call in
                { (api: API) -> EventLoopFuture<Response> in
                    try call.call(on: api).flatMap { returnValue in
                        EncodingHelper(returnValue).encodeResponse(for: request)
                    }
                }
            }
        }
    }
    
    func decodeCall(from request: Request) -> EventLoopFuture<MethodCall> {
        decodeCallAction(request)
    }
}

private struct EncodingHelper<Wrapped: Codable>: Content {
    var wrappedValue: Wrapped
    
    init(_ wrappedValue: Wrapped) {
        self.wrappedValue = wrappedValue
    }
    
    init(from decoder: Decoder) throws {
        wrappedValue = try Wrapped(from: decoder)
    }
    
    func encode(to encoder: Encoder) throws {
        try wrappedValue.encode(to: encoder)
    }
}
