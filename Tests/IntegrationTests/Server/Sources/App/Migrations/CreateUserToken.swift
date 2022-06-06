import Fluent

struct CreateUserToken: Fluent.AsyncMigration {
    var name: String { "CreateUserToken" }
    
    func prepare(on database: Database) async throws {
        try await database.schema("user_tokens")
            .id()
            .field("value", .string, .required)
            .field("user_id", .uuid, .required, .references("users", "id"))
            .field("expiration_date", .datetime, .required, .sql(.default("2020-01-01T00:00Z")))
            .unique(on: "value")
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("user_tokens").delete()
    }
}
