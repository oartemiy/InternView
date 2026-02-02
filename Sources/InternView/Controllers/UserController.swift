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
        userGroup.post(use: createHandler)
        userGroup.get(use: getAllHandler)
        userGroup.get(":userId", use: getHandler)
        
        let basicMW = User.authenticator()
        let guardMW = User.guardMiddleware()
        let protected = userGroup.grouped(basicMW, guardMW)
        protected.put(":userId", use: updateHandler)
        protected.delete(":userId", use: deleteHandler)
    }

    //MARK: CRUD
    
    //MARK: Create
    func createHandler(_ req: Request) async throws -> User.ResponseDTO {
        let createDTO = try req.content.decode(User.CreateDTO.self)
        
        // Проверка роли
        guard let role = UserRole(rawValue: createDTO.role) else {
            throw Abort(.badRequest, reason: "Invalid role. Must be 'intern' or 'recruiter'")
        }
        
        // Проверка уникальности логина
        let existingUser = try await User.query(on: req.db)
            .filter(\.$login == createDTO.login)
            .first()
        
        if existingUser != nil {
            throw Abort(.conflict, reason: "User with this login already exists")
        }
        
        // Хеширование пароля
        let hashedPassword = try Bcrypt.hash(createDTO.password)
        
        // Создание пользователя с хешированным паролем
        let user = User(from: createDTO, passwordHash: hashedPassword)
        try await user.save(on: req.db)
        
        return user.toResponseDTO()
    }

    //MARK: Retrive All
    func getAllHandler(_ req: Request) async throws -> [User.ResponseDTO] {
        let users = try await User.query(on: req.db).all()
        return users.map { $0.toResponseDTO() }
    }

    //MARK: Retrive
    func getHandler(_ req: Request) async throws -> User.ResponseDTO {
        guard let userId = req.parameters.get("userId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid User ID format")
        }

        guard let user = try await User.find(userId, on: req.db) else {
            throw Abort(.notFound, reason: "User with this ID does not exist")
        }

        return user.toResponseDTO()
    }

    //MARK: Update
    func updateHandler(_ req: Request) async throws -> User.ResponseDTO {
        guard let userId = req.parameters.get("userId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid User ID format")
        }

        let updateDTO = try req.content.decode(User.UpdateDTO.self)

        guard let user = try await User.find(userId, on: req.db) else {
            throw Abort(.notFound, reason: "User with this ID does not exist")
        }

        // Обновляем только те поля, которые переданы
        if let name = updateDTO.name { user.name = name }
        if let login = updateDTO.login { user.login = login }
        
        // Если передан новый пароль - хешируем его
        if let newPassword = updateDTO.password {
            let hashedPassword = try Bcrypt.hash(newPassword)
            user.password = hashedPassword
        }
        
        if let role = updateDTO.role {
            guard let _ = UserRole(rawValue: role) else {
                throw Abort(.badRequest, reason: "Invalid role. Must be 'intern' or 'recruiter'")
            }
            user.role = role
        }
        if let profilePic = updateDTO.profilePic { user.profilePic = profilePic }
        if let description = updateDTO.description { user.description = description }

        try await user.update(on: req.db)
        return user.toResponseDTO()
    }

    //MARK: Delete
    func deleteHandler(_ req: Request) async throws -> HTTPStatus {
        guard let userId = req.parameters.get("userId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid User ID format")
        }

        guard let user = try await User.find(userId, on: req.db) else {
            throw Abort(.notFound, reason: "User with this ID does not exist")
        }

        try await user.delete(on: req.db)
        return .noContent
    }
}
