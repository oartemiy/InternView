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
        let user = try req.auth.require(User.self)
        
        // Проверяем, что пользователь имеет роль intern
        guard user.role == UserRole.intern.rawValue else {
            throw Abort(.badRequest, reason: "Only users with 'intern' role can create CVs")
        }
        
        let createDTO = try req.content.decode(CV.CreateDTO.self)
        
        // Создаем CV с userID из авторизации
        let cv = CV(from: createDTO, userID: user.id!)
        try await cv.save(on: req.db)
        
        // Загружаем данные пользователя для ответа
        try await cv.$user.load(on: req.db)
        return cv.toResponseDTO(with: cv.user)
    }

    //MARK: Retrive All
    func getAllHandler(_ req: Request) async throws -> [CV.ResponseDTO] {
        // Загружаем CV с данными пользователя
        let cvs = try await CV.query(on: req.db)
            .with(\.$user)
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
        let user = try req.auth.require(User.self)
        
        guard let cvId = req.parameters.get("cvId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid CV ID format")
        }

        let updateDTO = try req.content.decode(CV.UpdateDTO.self)

        guard let cv = try await CV.find(cvId, on: req.db) else {
            throw Abort(.notFound, reason: "CV with this ID does not exist")
        }
        
        // Проверяем, что CV принадлежит пользователю
        guard cv.$user.id == user.id else {
            throw Abort(.forbidden, reason: "You can only update your own CVs")
        }

        // Обновляем поля
        cv.update(from: updateDTO)

        try await cv.update(on: req.db)
        
        // Загружаем обновленные данные пользователя
        try await cv.$user.load(on: req.db)
        return cv.toResponseDTO(with: cv.user)
    }

    //MARK: Delete
    func deleteHandler(_ req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        
        guard let cvId = req.parameters.get("cvId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid CV ID format")
        }

        guard let cv = try await CV.find(cvId, on: req.db) else {
            throw Abort(.notFound, reason: "CV with this ID does not exist")
        }
        
        // Проверяем, что CV принадлежит пользователю
        guard cv.$user.id == user.id else {
            throw Abort(.forbidden, reason: "You can only delete your own CVs")
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
