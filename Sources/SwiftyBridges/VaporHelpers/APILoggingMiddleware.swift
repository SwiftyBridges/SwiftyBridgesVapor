import Vapor

/// Logs the called API method and can be used as a replacement for `Vapor.RouteLoggingMiddleware`. If a request does not call a SwiftyBridges API method, the behavior falls back to `Vapor.RouteLoggingMiddleware`.
public final class APILoggingMiddleware: Middleware {
    public let logLevel: Logger.Level
    
    private let vaporMiddleware: RouteLoggingMiddleware
    
    public init(logLevel: Logger.Level = .info) {
        self.logLevel = logLevel
        self.vaporMiddleware = RouteLoggingMiddleware(logLevel: logLevel)
    }
    
    public func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        guard
            let apiType = request.headers["API-Type"].first,
            let method = request.headers["API-Method"].first
        else {
            return vaporMiddleware.respond(to: request, chainingTo: next)
        }
        
        request.logger.log(level: self.logLevel, "\(apiType).\(method) | \(request.url.path.removingPercentEncoding ?? request.url.path)")
        return next.respond(to: request)
    }
}
