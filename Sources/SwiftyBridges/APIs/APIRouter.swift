//
//  APIRouter.swift
//  APIRouter
//
//  Created by Stephen Kockentiedt on 16.09.21.
//

import Foundation
import Vapor

/// Responsible for routing API method requests to the correct API definitions
///
/// For instructions how to use it, see `README.md`.
public class APIRouter {
    /// Stores `APIRegistration` instances keyed by the name of the API definition type
    private var registrationByTypeName: [String: AsyncResponder] = [:]
    
    public init() {}
}


// MARK: - Public Members

extension APIRouter {
    /// Before an API Definition can be called via SwiftyBridges, it must first be registered with an `APIRouter`
    ///
    /// - Parameter api: The API definition type to be registered
    public func register<API: APIDefinition>(_ api: API.Type) {
        let typeName = String(describing: API.self)
        let registration = APIRegistration<API>()
        registrationByTypeName[typeName] = registration
    }
    
    /// Must be called inside a POST route to correctly handle API method requests.
    /// - Parameter request: The POST request sent by SwiftyBridgesClient
    /// - Returns: A response to be returned by the POST route
    public func handle(_ request: Request) async throws -> Response {
        guard let apiTypeName = request.headers["API-Type"].first else {
            throw Abort(.badRequest)
        }
        
        guard let registration = registrationByTypeName[apiTypeName] else {
            print("API definition type '\(apiTypeName)' has not been registered with this APIRouter.")
            throw Abort(.badRequest, reason: "API definition '\(apiTypeName)' has not been registered on the server")
        }
        
        return try await registration.respond(to: request)
    }
}
