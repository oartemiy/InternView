//
//  UserController.swift
//  InternView
//
//  Created by Артемий Образцов on 02.02.2026.
//

import Fluent
import Vapor

struct UserController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let userGroup = routes.grouped("users")
        userGroup.post("login", use: loginHandler)
        userGroup.post(use: createHandler)
        userGroup.get(use: getAllHandler)
        userGroup.get(":userId", use: getHandler)
        
        let basicMW = User.authenticator()
        let guardMW = User.guardMiddleware()
        let protected = userGroup.grouped(basicMW, guardMW)
        protected.put(":userId", use: updateHandler)
        protected.delete(":userId", use: deleteHandler)
    }

    // MARK: Create
    func createHandler(_ req: Request) async throws -> User.ResponseDTO {
        let createDTO = try req.content.decode(User.CreateDTO.self)

        // Проверка роли
        guard let role = UserRole(rawValue: createDTO.role) else {
            throw Abort(.badRequest, reason: "Invalid role")
        }

        // Уникальность логина
        let existing = try await User.query(on: req.db)
            .filter(\.$login == createDTO.login)
            .first()
        if existing != nil {
            throw Abort(.conflict, reason: "Login already exists")
        }

        // Обработка фото
        var profilePicPath: String?
        if let file = createDTO.profilePicFile {
            guard let ext = file.extension?.lowercased(),
                  ["jpg", "jpeg", "png", "gif", "heic"].contains(ext) else {
                throw Abort(.badRequest, reason: "Only image files are allowed")
            }
            guard file.data.readableBytes <= 5 * 1024 * 1024 else {
                throw Abort(.badRequest, reason: "File too large (max 5 MB)")
            }

            let filename = "\(UUID().uuidString).\(ext)"
            let path = req.application.directory.publicDirectory + "uploads/profile/" + filename
            try await req.fileio.writeFile(file.data, at: path)
            profilePicPath = "/uploads/profile/\(filename)"
        }

        let hashedPassword = try Bcrypt.hash(createDTO.password)
        let user = User(from: createDTO, passwordHash: hashedPassword, profilePicPath: profilePicPath)
        try await user.save(on: req.db)
        return user.toResponseDTO()
    }

    // MARK: Retrieve All
    func getAllHandler(_ req: Request) async throws -> [User.ResponseDTO] {
        let users = try await User.query(on: req.db).all()
        return users.map { $0.toResponseDTO() }
    }

    // MARK: Retrieve One
    func getHandler(_ req: Request) async throws -> User.ResponseDTO {
        guard let userId = req.parameters.get("userId", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        guard let user = try await User.find(userId, on: req.db) else {
            throw Abort(.notFound)
        }
        return user.toResponseDTO()
    }

    // MARK: Update
    func updateHandler(_ req: Request) async throws -> User.ResponseDTO {
        guard let userId = req.parameters.get("userId", as: UUID.self) else {
            throw Abort(.badRequest)
        }

        let updateDTO = try req.content.decode(User.UpdateDTO.self)

        guard let user = try await User.find(userId, on: req.db) else {
            throw Abort(.notFound)
        }

        // Обновляем текстовые поля
        if let name = updateDTO.name { user.name = name }
        if let login = updateDTO.login { user.login = login }
        if let newPassword = updateDTO.password {
            user.password = try Bcrypt.hash(newPassword)
        }
        if let role = updateDTO.role {
            guard UserRole(rawValue: role) != nil else {
                throw Abort(.badRequest, reason: "Invalid role")
            }
            user.role = role
        }
        if let description = updateDTO.description { user.description = description }

        // Обработка нового фото
        if let file = updateDTO.profilePicFile {
            guard let ext = file.extension?.lowercased(),
                  ["jpg", "jpeg", "png", "gif", "heic"].contains(ext) else {
                throw Abort(.badRequest, reason: "Only image files are allowed")
            }
            guard file.data.readableBytes <= 5 * 1024 * 1024 else {
                throw Abort(.badRequest, reason: "File too large (max 5 MB)")
            }

            let filename = "\(UUID().uuidString).\(ext)"
            let path = req.application.directory.publicDirectory + "uploads/profile/" + filename
            try await req.fileio.writeFile(file.data, at: path)

            // Удаляем старый файл
            if let oldPic = user.profilePic, !oldPic.isEmpty {
                let oldPath = req.application.directory.publicDirectory + oldPic.replacingOccurrences(of: "/uploads/", with: "uploads/")
                try? FileManager.default.removeItem(atPath: oldPath)
            }

            user.profilePic = "/uploads/profile/\(filename)"
        }

        try await user.update(on: req.db)
        return user.toResponseDTO()
    }
    
    // MARK: - Login
    func loginHandler(_ req: Request) async throws -> User.ResponseDTO {
        // Декодируем JSON с логином и паролем
        struct LoginRequest: Content {
            let login: String
            let password: String
        }
        let loginRequest = try req.content.decode(LoginRequest.self)
        
        // Ищем пользователя по логину
        guard let user = try await User.query(on: req.db)
            .filter(\.$login == loginRequest.login)
            .first() else {
            throw Abort(.unauthorized, reason: "Invalid credentials")
        }
        
        // Проверяем пароль
        guard try user.verify(password: loginRequest.password) else {
            throw Abort(.unauthorized, reason: "Invalid credentials")
        }
        
        // Возвращаем пользователя (без пароля)
        return user.toResponseDTO()
    }

    // MARK: Delete
    func deleteHandler(_ req: Request) async throws -> HTTPStatus {
        guard let userId = req.parameters.get("userId", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        guard let user = try await User.find(userId, on: req.db) else {
            throw Abort(.notFound)
        }

        // Удаляем фото, если есть
        if let pic = user.profilePic, !pic.isEmpty {
            let filePath = req.application.directory.publicDirectory + pic.replacingOccurrences(of: "/uploads/", with: "uploads/")
            try? FileManager.default.removeItem(atPath: filePath)
        }

        try await user.delete(on: req.db)
        return .noContent
    }
}
