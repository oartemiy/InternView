//
//  User+DTO.swift
//  InternView
//
//  Created by Артемий Образцов on 02.02.2026.
//

import Vapor

extension User {
    // DTO для создания пользователя (фото опционально)
    struct CreateDTO: Content {
        let name: String
        let login: String
        let password: String
        let role: String
        let description: String?
        var profilePicFile: File?      // опциональный файл
    }

    // DTO для обновления (все опционально)
    struct UpdateDTO: Content {
        let name: String?
        let login: String?
        let password: String?
        let role: String?
        let description: String?
        var profilePicFile: File?      // новый файл фото
    }

    // DTO для ответа (без изменений)
    struct ResponseDTO: Content {
        let id: UUID
        let name: String
        let login: String
        let role: String
        let profilePic: String?
        let description: String?
        let createdAt: Date?
    }

    // Конвертация из CreateDTO в модель
    convenience init(from dto: CreateDTO, passwordHash: String, profilePicPath: String?) {
        self.init(
            name: dto.name,
            login: dto.login,
            password: passwordHash,
            role: dto.role,
            profilePic: profilePicPath,
            description: dto.description
        )
    }

    // Конвертация в ResponseDTO
    func toResponseDTO() -> ResponseDTO {
        ResponseDTO(
            id: self.id ?? UUID(),
            name: self.name,
            login: self.login,
            role: self.role,
            profilePic: self.profilePic,
            description: self.description,
            createdAt: self.createdAt
        )
    }
}
