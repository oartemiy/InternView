//
//  VacancyApplication.swift
//  InternView
//
//  Created by Артемий Образцов on 07.02.2026.
//

import Fluent
import Vapor

final class VacancyApplication: Model, Content, @unchecked Sendable {
    static let schema = "vacancy_applications"
    
    @ID(key: .id)
    var id: UUID?
    
    // Связь с вакансией
    @Parent(key: "vacancy_id")
    var vacancy: Vacancy
    
    // Связь с интерном (тем, кто откликнулся)
    @Parent(key: "intern_id")
    var intern: User
    
    // Информация об отклике
    @Field(key: "status")
    var status: String
    
    @Field(key: "cover_letter")
    var coverLetter: String?
    
    @Field(key: "resume_url")
    var resumeURL: String?
    
    // Ссылка на CV интерна
    @OptionalParent(key: "cv_id")
    var cv: CV?
    
    @Timestamp(key: "applied_at", on: .create)
    var appliedAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    init() {}
    
    init(
        id: UUID? = nil,
        vacancyID: Vacancy.IDValue,
        internID: User.IDValue,
        cvID: CV.IDValue? = nil,
        status: String = "pending",
        coverLetter: String? = nil,
        resumeURL: String? = nil
    ) {
        self.id = id
        self.$vacancy.id = vacancyID
        self.$intern.id = internID
        self.$cv.id = cvID
        self.status = status
        self.coverLetter = coverLetter
        self.resumeURL = resumeURL
    }
}
