//
//  Vacancy.swift
//  InternView
//
//  Created by Артемий Образцов on 07.02.2026.
//

import Fluent
import Vapor

final class Vacancy: Model, Content, @unchecked Sendable {
    static let schema = "vacancies"
    
    @ID(key: .id)
    var id: UUID?
    
    // Основная информация
    @Field(key: "title")
    var title: String
    
    @Field(key: "description")
    var description: String
    
    @Field(key: "requirements")
    var requirements: [String]
    
    @Field(key: "salary_range")
    var salaryRange: String?
    
    @Field(key: "location")
    var location: String
    
    @Field(key: "work_mode")
    var workMode: String
    
    @Field(key: "experience_level")
    var experienceLevel: String
    
    @Field(key: "is_active")
    var isActive: Bool
    
    // Связь с рекрутером (создателем вакансии)
    @Parent(key: "recruiter_id")
    var recruiter: User
    
    // Даты
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    @Timestamp(key: "expires_at", on: .none)
    var expiresAt: Date?
    
    // Связь с откликами через VacancyApplication
    @Children(for: \.$vacancy)
    var applications: [VacancyApplication]
    
    init() {}
    
    init(
        id: UUID? = nil,
        title: String,
        description: String,
        requirements: [String],
        salaryRange: String? = nil,
        location: String,
        workMode: String,
        experienceLevel: String,
        isActive: Bool = true,
        recruiterID: User.IDValue,
        expiresAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.requirements = requirements
        self.salaryRange = salaryRange
        self.location = location
        self.workMode = workMode
        self.experienceLevel = experienceLevel
        self.isActive = isActive
        self.$recruiter.id = recruiterID
        self.expiresAt = expiresAt
    }
}
