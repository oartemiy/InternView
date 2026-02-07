//
//  CreateCV.swift
//  InternView
//
//  Created by Артемий Образцов on 01.02.2026.
//

import Fluent
import Vapor

struct CreateCV: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("cvs")
            .id()
            .field("title", .string, .required)
            .field("description", .string, .required)
            .field("user_id", .uuid, .required) // Меняем с .string на .uuid
            .foreignKey("user_id", references: "users", "id", onDelete: .cascade) // Добавляем внешний ключ
            .field("pdf", .string, .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("cvs").delete()
    }
}
