import Fluent
import FluentSQLiteDriver
import SwiftyBridges
import Vapor

let apiRouter = APIRouter()

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)

    app.migrations.add(CreateUser())
    app.migrations.add(CreateUserToken())
    
    apiRouter.register(BasicTestAPI.self)
    apiRouter.register(GenerateClientStructTestAPI.self)
    apiRouter.register(ValidationTestAPI.self)
    apiRouter.register(MiddlewareTestAPI.self)

    // register routes
    try routes(app)
}
