import Fluent
import Vapor

func routes(_ app: Application) throws {
    app.post("api") { req in
        try await apiRouter.handle(req)
    }
}
