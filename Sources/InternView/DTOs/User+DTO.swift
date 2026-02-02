//
//  User+DTO.swift
//  InternView
//
//  Created by Артемий Образцов on 02.02.2026.
//

import Vapor

extension User {
    // DTO для создания пользователя
    struct CreateDTO: Content {
        let name: String
        let login: String
        let password: String  // Пароль в открытом виде
        let role: String
        let profilePic: String?
        let description: String?
    }

    // DTO для обновления пользователя
    struct UpdateDTO: Content {
        let name: String?
        let login: String?
        let password: String?  // Пароль в открытом виде (опционально)
        let role: String?
        let profilePic: String?
        let description: String?
    }

    // DTO для ответа (чтения) пользователя
    struct ResponseDTO: Content {
        let id: UUID
        let name: String
        let login: String
        let role: String
        let profilePic: String?
        let description: String?
        let createdAt: Date?
    }

    // Конвертация из CreateDTO в User модель с хешированием пароля
    convenience init(from dto: CreateDTO, passwordHash: String) {
        self.init(
            name: dto.name,
            login: dto.login,
            password: passwordHash,  // Используем хешированный пароль
            role: dto.role,
            profilePic: dto.profilePic,
            description: dto.description
        )
    }

    // Конвертация из User модели в ResponseDTO
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
