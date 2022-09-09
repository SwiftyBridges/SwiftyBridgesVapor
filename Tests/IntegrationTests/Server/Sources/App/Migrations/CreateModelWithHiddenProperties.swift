import Fluent

struct CreateModelWithHiddenProperties: AsyncMigration {
    var name: String { "CreateModelWithHiddenProperties" }
    
    func prepare(on database: Database) async throws {
        let hiddenEnum = try await database.enum("hidden_enum")
            .case("hiddenCase")
            .create()

        try await database.schema("models_with_hidden_properties")
            .id()
            .field("name", .string, .required)
            .field("hidden_boolean", .string, .required)
            .field("hidden_enum", hiddenEnum, .required)
            .field("hidden_field", .string, .required)
            .field("hidden_group_field_in_group", .string, .required)
            .field("hidden_boolean2", .string)
            .field("hidden_optional_enum", hiddenEnum)
            .field("hidden_optional_field", .string)
            .field("hidden_optional_parent", .uuid, .references("hidden_parents", "id"))
            .field("hidden_parent", .uuid, .required, .references("hidden_parents", "id"))
            .field("hidden_timestamp", .datetime)
            .create()

        try await database.schema("hidden_parents")
            .id()
            .create()

        try await database.schema("hidden_siblings")
            .id()
            .create()

        try await database.schema("pivots")
            .id()
            .field("source_id", .uuid, .required, .references("models_with_hidden_properties", "id"))
            .field("target_id", .uuid, .required, .references("hidden_siblings", "id"))
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("users").delete()
        try await database.schema("hidden_parents").delete()
        try await database.schema("hidden_siblings").delete()
        try await database.schema("pivots").delete()
    }
}