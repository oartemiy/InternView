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
        let schema = database.schema("cvs")
            .id()
            .field("title", .string, .required)
            .field("description", .string, .required)
            .field("user_id", .string, .required)
            .field("pdf", .string, .required)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
        try await schema.create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("cvs").delete()
    }
}
