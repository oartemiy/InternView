//
//  Vacancy+DTO.swift
//  InternView
//
//  Created by Артемий Образцов on 07.02.2026.
//

import Vapor

extension Vacancy {
    struct CreateUpdateDTO: Content {
        let title: String
        let description: String
        let requirements: [String]
        let salaryRange: String?
        let location: String
        let workMode: String
        let experienceLevel: String
        let expiresAt: Date?
    }
    
    // Основной ResponseDTO с рекрутером
    struct ResponseDTO: Content {
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
        let recruiter: User.ResponseDTO
        let applicationCount: Int
        let createdAt: Date?
        let updatedAt: Date?
        let expiresAt: Date?
    }
    
    convenience init(from dto: CreateUpdateDTO, recruiterID: User.IDValue) {
        self.init(
            title: dto.title,
            description: dto.description,
            requirements: dto.requirements,
            salaryRange: dto.salaryRange,
            location: dto.location,
            workMode: dto.workMode,
            experienceLevel: dto.experienceLevel,
            recruiterID: recruiterID,
            expiresAt: dto.expiresAt
        )
    }
    
    // Конвертация с загруженным рекрутером
    func toResponseDTO(
        applicationCount: Int = 0,
        recruiter: User? = nil
    ) -> ResponseDTO {
        guard let recruiter = recruiter else {
            fatalError("Recruiter must be loaded before converting to ResponseDTO")
        }
        
        return ResponseDTO(
            id: self.id ?? UUID(),
            title: self.title,
            description: self.description,
            requirements: self.requirements,
            salaryRange: self.salaryRange,
            location: self.location,
            workMode: self.workMode,
            experienceLevel: self.experienceLevel,
            isActive: self.isActive,
            recruiterId: self.$recruiter.id,
            recruiter: recruiter.toResponseDTO(),
            applicationCount: applicationCount,
            createdAt: self.createdAt,
            updatedAt: self.updatedAt,
            expiresAt: self.expiresAt
        )
    }
    
    // Упрощенный DTO без рекрутера (для списка)
    struct SimpleDTO: Content {
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
    }
    
    func toSimpleDTO(applicationCount: Int = 0) -> SimpleDTO {
        SimpleDTO(
            id: self.id ?? UUID(),
            title: self.title,
            description: self.description,
            requirements: self.requirements,
            salaryRange: self.salaryRange,
            location: self.location,
            workMode: self.workMode,
            experienceLevel: self.experienceLevel,
            isActive: self.isActive,
            recruiterId: self.$recruiter.id,
            applicationCount: applicationCount,
            createdAt: self.createdAt,
            expiresAt: self.expiresAt
        )
    }
}
