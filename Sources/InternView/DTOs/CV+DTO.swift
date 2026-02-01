//
//  CVDTO.swift
//  InternView
//
//  Created by Артемий Образцов on 01.02.2026.
//

import Vapor

extension CV {
    // DTO для создания CV
    struct CreateDTO: Content {
        var title: String
        var description: String
        var user_id: String
        var pdf: String
    }

    // DTO для ответа (чтения) CV
    struct ResponseDTO: Content {
        var id: UUID
        var title: String
        var description: String
        var user_id: String
        var pdf: String
        var created_at: Date?
        var updated_at: Date?
    }

    // Конвертация из CreateDTO в CV модель
    convenience init(from dto: CreateDTO) {
        self.init(
            title: dto.title,
            description: dto.description,
            user_id: dto.user_id,
            pdf: dto.pdf
        )
    }

    // Конвертация из CV модели в ResponseDTO
    func toResponseDTO() -> ResponseDTO {
        ResponseDTO(
            id: self.id ?? UUID(),
            title: self.title,
            description: self.description,
            user_id: self.user_id,
            pdf: self.pdf,
            created_at: self.created_at,
            updated_at: self.updated_at
        )
    }
}
