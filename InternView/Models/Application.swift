//
//  Application.swift
//  InternView
//
//  Created by Артемий Образцов on 01.03.2026.
//

import Foundation

struct Application: Codable, Identifiable {
    let id: UUID
    let vacancyId: UUID
    let internId: UUID
    let cvId: UUID
    let status: String
    let coverLetter: String?
    let resumeUrl: String?
    let appliedAt: Date?
    let updatedAt: Date?
    let intern: User?
    let cv: CV?
    let vacancy: Vacancy? // для интерна полезно знать название вакансии

    enum CodingKeys: String, CodingKey {
        case id
        case vacancyId = "vacancy_id"
        case internId = "intern_id"
        case cvId = "cv_id"
        case status
        case coverLetter = "cover_letter"
        case resumeUrl = "resume_url"
        case appliedAt = "applied_at"
        case updatedAt = "updated_at"
        case intern
        case cv
        case vacancy
    }
}
