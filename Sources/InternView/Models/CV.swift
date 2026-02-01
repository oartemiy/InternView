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
    var user_id: String

    @Field(key: "pdf")
    var pdf: String

    init() {}

    init(
        id: UUID? = nil,
        title: String,
        description: String,
        user_id: String,
        pdf: String
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.user_id = user_id
        self.pdf = pdf
    }

}
