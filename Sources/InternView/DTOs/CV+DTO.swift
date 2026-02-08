//
//  CV+DTO.swift
//  InternView
//
//  Created by Артемий Образцов on 01.02.2026.
//

import Vapor

extension CV {
    // DTO для создания CV (теперь без userId)
    struct CreateDTO: Content {
        let title: String
        let description: String
        let pdf: String
    }
    
    // DTO для обновления CV
    struct UpdateDTO: Content {
        let title: String?
        let description: String?
        let pdf: String?
    }

    // DTO для ответа (чтения) CV
    struct ResponseDTO: Content {
        let id: UUID
        let title: String
        let description: String
        let userId: UUID
        let user: User.ResponseDTO? // Опционально, если нужно включать данные пользователя
        let pdf: String
        let createdAt: Date?
        let updatedAt: Date?
    }

    // Конвертация из CreateDTO в CV модель (теперь с userID параметром)
    convenience init(from dto: CreateDTO, userID: User.IDValue) {
        self.init(
            title: dto.title,
            description: dto.description,
            userID: userID,
            pdf: dto.pdf
        )
    }
    
    // Конвертация из UpdateDTO в CV модель
    func update(from dto: UpdateDTO) {
        if let title = dto.title {
            self.title = title
        }
        if let description = dto.description {
            self.description = description
        }
        if let pdf = dto.pdf {
            self.pdf = pdf
        }
    }

    // Конвертация из CV модели в ResponseDTO (базовая версия без пользователя)
    func toResponseDTO() -> ResponseDTO {
        ResponseDTO(
            id: self.id ?? UUID(),
            title: self.title,
            description: self.description,
            userId: self.$user.id,
            user: nil,
            pdf: self.pdf,
            createdAt: self.createdAt,
            updatedAt: self.updatedAt
        )
    }

    // Расширенная версия с данными пользователя
    func toResponseDTO(with user: User? = nil) -> ResponseDTO {
        let userDTO = user?.toResponseDTO()
        return ResponseDTO(
            id: self.id ?? UUID(),
            title: self.title,
            description: self.description,
            userId: self.$user.id,
            user: userDTO,
            pdf: self.pdf,
            createdAt: self.createdAt,
            updatedAt: self.updatedAt
        )
    }
}
