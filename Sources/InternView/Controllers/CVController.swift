//
//  CVController.swift
//  InternView
//
//  Created by Артемий Образцов on 01.02.2026.
//

import Fluent
import Vapor

struct CVController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let cvGroup = routes.grouped("cvs")
        cvGroup.get(use: getAllHandler)
        cvGroup.get(":cvId", use: getHandler)
        cvGroup.get("user", ":userId", use: getCVsByUserHandler)
        
        let basicMW = User.authenticator()
        let guardMW = User.guardMiddleware()
        let protected = cvGroup.grouped(basicMW, guardMW)
        protected.post(use: createHandler)
        protected.put(":cvId", use: updateHandler)
        protected.delete(":cvId", use: deleteHandler)
    }
    
    //MARK: CRUD
    
    //MARK: Create
    func createHandler(_ req: Request) async throws -> CV.ResponseDTO {
        let createDTO = try req.content.decode(CV.CreateUpdateDTO.self)
        
        // Проверяем, существует ли пользователь
        guard let user = try await User.find(createDTO.userId, on: req.db) else {
            throw Abort(.notFound, reason: "User with ID \(createDTO.userId) not found")
        }
        
        // Проверяем, что пользователь имеет роль intern
        guard user.role == UserRole.intern.rawValue else {
            throw Abort(.badRequest, reason: "Only users with 'intern' role can create CVs")
        }
        
        let cv = CV(from: createDTO)
        try await cv.save(on: req.db)
        
        // Загружаем данные пользователя для ответа
        try await cv.$user.load(on: req.db)
        return cv.toResponseDTO(with: cv.user)
    }

    //MARK: Retrive All
    func getAllHandler(_ req: Request) async throws -> [CV.ResponseDTO] {
        // Загружаем CV с данными пользователя
        let cvs = try await CV.query(on: req.db)
            .with(\.$user) // Загружаем связанного пользователя
            .all()
        
        return cvs.map { cv in
            cv.toResponseDTO(with: cv.user)
        }
    }

    //MARK: Retrive
    func getHandler(_ req: Request) async throws -> CV.ResponseDTO {
        guard let cvId = req.parameters.get("cvId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid CV ID format")
        }

        // Загружаем CV с данными пользователя
        guard let cv = try await CV.query(on: req.db)
            .filter(\.$id == cvId)
            .with(\.$user)
            .first() else {
            throw Abort(.notFound, reason: "CV with this ID does not exist")
        }

        return cv.toResponseDTO(with: cv.user)
    }

    //MARK: Update
    func updateHandler(_ req: Request) async throws -> CV.ResponseDTO {
        guard let cvId = req.parameters.get("cvId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid CV ID format")
        }

        let updateDTO = try req.content.decode(CV.CreateUpdateDTO.self)

        // Проверяем существование пользователя, если обновляется userId
        if let user = try await User.find(updateDTO.userId, on: req.db) {
            guard user.role == UserRole.intern.rawValue else {
                throw Abort(.badRequest, reason: "Only users with 'intern' role can own CVs")
            }
        } else {
            throw Abort(.notFound, reason: "User with ID \(updateDTO.userId) not found")
        }

        guard let cv = try await CV.find(cvId, on: req.db) else {
            throw Abort(.notFound, reason: "CV with this ID does not exist")
        }

        cv.title = updateDTO.title
        cv.description = updateDTO.description
        cv.$user.id = updateDTO.userId // Обновляем связь с пользователем
        cv.pdf = updateDTO.pdf

        try await cv.update(on: req.db)
        
        // Загружаем обновленные данные пользователя
        try await cv.$user.load(on: req.db)
        return cv.toResponseDTO(with: cv.user)
    }

    //MARK: Delete
    func deleteHandler(_ req: Request) async throws -> HTTPStatus {
        guard let cvId = req.parameters.get("cvId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid CV ID format")
        }

        guard let cv = try await CV.find(cvId, on: req.db) else {
            throw Abort(.notFound, reason: "CV with this ID does not exist")
        }

        try await cv.delete(on: req.db)
        return .noContent
    }
    
    // Дополнительный хендлер: получение всех CV конкретного пользователя
    func getCVsByUserHandler(_ req: Request) async throws -> [CV.ResponseDTO] {
        guard let userId = req.parameters.get("userId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid User ID format")
        }
        
        let cvs = try await CV.query(on: req.db)
            .filter(\.$user.$id == userId)
            .with(\.$user)
            .all()
        
        return cvs.map { cv in
            cv.toResponseDTO(with: cv.user)
        }
    }
}
