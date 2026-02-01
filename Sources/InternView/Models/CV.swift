//
//  CV.swift
//  InternView
//
//  Created by Артемий Образцов on 01.02.2026.
//

import Fluent
import Vapor

final class CV: Model, Content, @unchecked Sendable {

    static let schema: String = "CVs"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "title")
    var title: String

    @Field(key: "description")
    var description: String

    @Field(key: "user_id")
    var userId: UUID?

    @Timestamp(key: "created_at", on: .create, format: .iso8601)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update, format: .iso8601)
    var updatedAt: Date?

    @Timestamp(key: "deleted_at", on: .delete, format: .iso8601)
    var deletedAt: Date?

    @Field(key: "pdf")
    var pdf: String

    init() {}

    init(
        id: UUID? = nil,
        title: String,
        description: String,
        userId: UUID? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil,
        deletedAt: Date? = nil,
        pdf: String
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.userId = userId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.pdf = pdf
    }

}
