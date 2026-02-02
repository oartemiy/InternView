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
        let cv = CV(from: createDTO)
        try await cv.save(on: req.db)
        return cv.toResponseDTO()
    }

    //MARK: Retrive All
    func getAllHandler(_ req: Request) async throws -> [CV.ResponseDTO] {
        let cvs = try await CV.query(on: req.db).all()
        return cvs.map { $0.toResponseDTO() }
    }

    //MARK: Retrive
    func getHandler(_ req: Request) async throws -> CV.ResponseDTO {
        guard let cvId = req.parameters.get("cvId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid CV ID format")
        }

        guard let cv = try await CV.find(cvId, on: req.db) else {
            throw Abort(.notFound, reason: "CV with this ID does not exist")
        }

        return cv.toResponseDTO()
    }

    //MARK: Update
    func updateHandler(_ req: Request) async throws -> CV.ResponseDTO {
        guard let cvId = req.parameters.get("cvId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid CV ID format")
        }

        // Декодируем JSON из тела запроса
        let updateDTO = try req.content.decode(CV.CreateUpdateDTO.self)

        guard let cv = try await CV.find(cvId, on: req.db) else {
            throw Abort(.notFound, reason: "CV with this ID does not exist")
        }

        cv.title = updateDTO.title
        cv.description = updateDTO.description
        cv.userId = updateDTO.userId
        cv.pdf = updateDTO.pdf

        try await cv.update(on: req.db)
        return cv.toResponseDTO()
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
}
