//
//  CV+DTO.swift
//  InternView
//
//  Created by Артемий Образцов on 01.02.2026.
//  Data Transfer Object

import Vapor

extension CV {
    // DTO для создания и обновления CV
    struct CreateUpdateDTO: Content {
        let title: String
        let description: String
        let userId: String
        let pdf: String
    }

    // DTO для ответа (чтения) CV
    struct ResponseDTO: Content {
        let id: UUID
        let title: String
        let description: String
        let userId: String
        let pdf: String
        let createdAt: Date?
        let updatedAt: Date?
    }

    // Конвертация из DTO в CV модель
    convenience init(from dto: CreateUpdateDTO) {
        self.init(
            title: dto.title,
            description: dto.description,
            userId: dto.userId,
            pdf: dto.pdf
        )
    }

    // Конвертация из CV модели в ResponseDTO
    func toResponseDTO() -> ResponseDTO {
        ResponseDTO(
            id: self.id ?? UUID(),
            title: self.title,
            description: self.description,
            userId: self.userId,
            pdf: self.pdf,
            createdAt: self.createdAt,
            updatedAt: self.updatedAt
        )
    }
}
