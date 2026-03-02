//
//  Vacancy.swift
//  InternView
//
//  Created by Артемий Образцов on 01.03.2026.
//

import Foundation


struct Vacancy: Codable, Identifiable {
    let id: UUID
    let title: String
    let description: String
    let requirements: [String]
    let salaryRange: String?
    let location: String
    let workMode: String
    let experienceLevel: String
    let isActive: Bool
    let recruiterId: UUID
    let createdAt: Date?
    let updatedAt: Date?
    let expiresAt: Date?
    let recruiter: User?          // может приходить в детальном ответе
    let applicationCount: Int?    // количество откликов (для списка)

    enum CodingKeys: String, CodingKey {
        case id, title, description, requirements, location
        case salaryRange = "salary_range"
        case workMode = "work_mode"
        case experienceLevel = "experience_level"
        case isActive = "is_active"
        case recruiterId = "recruiter_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case expiresAt = "expires_at"
        case recruiter
        case applicationCount = "application_count"
    }
}

// MARK: - DTO для создания и обновления вакансии
extension Vacancy {
    struct CreateUpdate: Codable {
        let title: String
        let description: String
        let requirements: [String]
        let salaryRange: String?
        let location: String
        let workMode: String
        let experienceLevel: String
        let expiresAt: Date?

        enum CodingKeys: String, CodingKey {
            case title, description, requirements, location
            case salaryRange = "salary_range"
            case workMode = "work_mode"
            case experienceLevel = "experience_level"
            case expiresAt = "expires_at"
        }
    }
}

// MARK: - Упрощённая модель для списка (если сервер присылает SimpleDTO)
extension Vacancy {
    struct Simple: Codable, Identifiable {
        let id: UUID
        let title: String
        let description: String
        let requirements: [String]
        let salaryRange: String?
        let location: String
        let workMode: String
        let experienceLevel: String
        let isActive: Bool
        let recruiterId: UUID
        let applicationCount: Int
        let createdAt: Date?
        let expiresAt: Date?

        enum CodingKeys: String, CodingKey {
            case id, title, description, requirements, location
            case salaryRange = "salary_range"
            case workMode = "work_mode"
            case experienceLevel = "experience_level"
            case isActive = "is_active"
            case recruiterId = "recruiter_id"
            case applicationCount = "application_count"
            case createdAt = "created_at"
            case expiresAt = "expires_at"
        }
    }
}
