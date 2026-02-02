//
//  CreateUser.swift
//  InternView
//
//  Created by Артемий Образцов on 02.02.2026.
//

import Vapor
import Fluent

struct CreateUser: AsyncMigration {
    func prepare(on database: any Database) async throws {
        let schema = database.schema("users")
            .id()
            .field("name", .string, .required)
            .field("login", .string, .required)
            .field("password", .string, .required)
            .field("role", .string, .required)
            .field("profile_pic", .string)
            .field("description", .string)
            .field("created_at", .datetime)
            .unique(on: "login")
        try await schema.create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema("users").delete()
    }
    
    
}
