//
//  CV.swift
//  InternView
//
//  Created by Артемий Образцов on 01.02.2026.
//

import Fluent
import Vapor

final class CV: Model, Content, @unchecked Sendable {
    static let schema: String = "cvs"  // В базе данных используем snake_case для таблиц

    @ID(key: .id)
    var id: UUID?

    @Field(key: "title")
    var title: String

    @Field(key: "description")
    var description: String

    @Field(key: "user_id")  // В базе snake_case
    var userId: String  // В модели camelCase

    @Field(key: "pdf")
    var pdf: String

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    init() {}

    init(
        id: UUID? = nil,
        title: String,
        description: String,
        userId: String,
        pdf: String,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.userId = userId
        self.pdf = pdf
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
