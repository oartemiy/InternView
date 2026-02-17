//
//  CV+DTO.swift
//  InternView
//
//  Created by Артемий Образцов on 01.02.2026.
//

import Vapor

extension CV {
    // DTO для создания CV (файл опционален)
    struct CreateDTO: Content {
        let title: String
        let description: String
        var pdfFile: File?      // если файл не приложен, будет nil
    }
    
    // DTO для обновления CV (все поля опциональны)
    struct UpdateDTO: Content {
        let title: String?
        let description: String?
        var pdfFile: File?      // новый файл для замены
    }

    // DTO для ответа (без изменений)
    struct ResponseDTO: Content {
        let id: UUID
        let title: String
        let description: String
        let userId: UUID
        let user: User.ResponseDTO?
        let pdf: String          // путь к файлу (может быть пустым)
        let createdAt: Date?
        let updatedAt: Date?
    }

    // Конвертация из CreateDTO в модель
    convenience init(from dto: CreateDTO, userID: User.IDValue, pdfPath: String) {
        self.init(
            title: dto.title,
            description: dto.description,
            userID: userID,
            pdf: pdfPath
        )
    }
    
    // Обновление из UpdateDTO (текстовые поля)
    func update(from dto: UpdateDTO) {
        if let title = dto.title { self.title = title }
        if let description = dto.description { self.description = description }
    }

    // Конвертация в ResponseDTO (с пользователем)
    func toResponseDTO(with user: User? = nil) -> ResponseDTO {
        ResponseDTO(
            id: self.id ?? UUID(),
            title: self.title,
            description: self.description,
            userId: self.$user.id,
            user: user?.toResponseDTO(),
            pdf: self.pdf,
            createdAt: self.createdAt,
            updatedAt: self.updatedAt
        )
    }
}
