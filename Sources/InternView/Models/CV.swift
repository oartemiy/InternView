//
//  CV.swift
//  InternView
//
//  Created by Артемий Образцов on 01.02.2026.
//

import Fluent
import Vapor

final class CV: Model, Content, @unchecked Sendable {
    static let schema: String = "cvs"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "title")
    var title: String

    @Field(key: "description")
    var description: String

    @Parent(key: "user_id")
    var user: User

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
        userID: User.IDValue, // Теперь принимаем UUID пользователя
        pdf: String,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.$user.id = userID // Устанавливаем связь
        self.pdf = pdf
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
