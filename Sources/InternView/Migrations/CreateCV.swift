//
//  CreateCV.swift
//  InternView
//
//  Created by Артемий Образцов on 01.02.2026.
//

import Fluent
import Vapor

struct CreateCV: Migration {
    func prepare(on database: any FluentKit.Database) -> NIOCore.EventLoopFuture<Void> {
        database.schema("CVs")
            .id()
            .field("title", .string, .required)
            .field("description", .string, .required)
            .field("user_id", .string, .required)
//            .field("created_at", .datetime)
//            .field("updated_at", .datetime)
//            .field("deleted_at", .datetime)
            .field("pdf", .string, .required)
            .create()
    }
    
    func revert(on database: any FluentKit.Database) -> NIOCore.EventLoopFuture<Void> {
        database.schema("CVs").delete()
    }
    
    
}
