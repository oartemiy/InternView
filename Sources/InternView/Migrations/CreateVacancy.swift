//
//  CreateVacancy.swift
//  InternView
//
//  Created by Артемий Образцов on 05.02.2026.
//

import Fluent
import Vapor

struct CreateVacancy: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("vacancies")
            .id()
            .field("title", .string, .required)
            .field("description", .string, .required)
            .field("requirements", .array(of: .string), .required)
            .field("salary_range", .string)
            .field("location", .string, .required)
            .field("work_mode", .string, .required)
            .field("experience_level", .string, .required)
            .field("is_active", .bool, .required, .custom("DEFAULT true"))
            .field("recruiter_id", .uuid, .required)
            .foreignKey("recruiter_id", references: "users", "id", onDelete: .cascade)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .field("expires_at", .datetime)
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema("vacancies").delete()
    }
}
