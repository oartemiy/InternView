//
//  CreateVacancyApplication.swift
//  InternView
//
//  Created by Артемий Образцов on 07.02.2026.
//

import Fluent
import Vapor

struct CreateVacancyApplication: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("vacancy_applications")
            .id()
            .field("vacancy_id", .uuid, .required)
            .foreignKey("vacancy_id", references: "vacancies", "id", onDelete: .cascade)
            .field("intern_id", .uuid, .required)
            .foreignKey("intern_id", references: "users", "id", onDelete: .cascade)
            .field("cv_id", .uuid)
            .foreignKey("cv_id", references: "cvs", "id", onDelete: .setNull)
            .field("status", .string, .required, .custom("DEFAULT 'pending'"))
            .field("cover_letter", .string)
            .field("resume_url", .string)
            .field("applied_at", .datetime)
            .field("updated_at", .datetime)
            .unique(on: "vacancy_id", "intern_id")
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema("vacancy_applications").delete()
    }
}
