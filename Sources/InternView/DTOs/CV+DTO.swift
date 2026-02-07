//
//  CV+DTO.swift
//  InternView
//
//  Created by Артемий Образцов on 01.02.2026.
//

import Vapor

extension CV {
    // DTO для создания и обновления CV
    struct CreateUpdateDTO: Content {
        let title: String
        let description: String
        let userId: UUID // Теперь UUID вместо String
        let pdf: String
    }

    // DTO для ответа (чтения) CV
    struct ResponseDTO: Content {
        let id: UUID
        let title: String
        let description: String
        let userId: UUID // Теперь UUID вместо String
        let user: User.ResponseDTO? // Опционально, если нужно включать данные пользователя
        let pdf: String
        let createdAt: Date?
        let updatedAt: Date?
    }

    // Конвертация из DTO в CV модель
    convenience init(from dto: CreateUpdateDTO) {
        self.init(
            title: dto.title,
            description: dto.description,
            userID: dto.userId, // Используем userID вместо userId
            pdf: dto.pdf
        )
    }

    // Конвертация из CV модели в ResponseDTO (базовая версия без пользователя)
    func toResponseDTO() -> ResponseDTO {
        ResponseDTO(
            id: self.id ?? UUID(),
            title: self.title,
            description: self.description,
            userId: self.$user.id, // Получаем ID пользователя из связи
            user: nil, // По умолчанию не включаем данные пользователя
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
            user: userDTO, // Включаем данные пользователя если переданы
            pdf: self.pdf,
            createdAt: self.createdAt,
            updatedAt: self.updatedAt
        )
    }
}
