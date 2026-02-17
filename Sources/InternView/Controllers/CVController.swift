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
    
    // MARK: Create
    func createHandler(_ req: Request) async throws -> CV.ResponseDTO {
        let user = try req.auth.require(User.self)
        guard user.role == UserRole.intern.rawValue else {
            throw Abort(.badRequest, reason: "Only interns can create CVs")
        }

        let createDTO = try req.content.decode(CV.CreateDTO.self)

        // Обработка файла PDF
        var pdfPath = ""
        if let file = createDTO.pdfFile {
            guard let ext = file.extension?.lowercased(), ext == "pdf" else {
                throw Abort(.badRequest, reason: "Only PDF files are allowed")
            }
            guard file.data.readableBytes <= 10 * 1024 * 1024 else {
                throw Abort(.badRequest, reason: "File too large (max 10 MB)")
            }

            let filename = "\(UUID().uuidString).pdf"
            let path = req.application.directory.publicDirectory + "uploads/cv/" + filename
            try await req.fileio.writeFile(file.data, at: path)
            pdfPath = "/uploads/cv/\(filename)"
        }

        let cv = CV(from: createDTO, userID: user.id!, pdfPath: pdfPath)
        try await cv.save(on: req.db)
        try await cv.$user.load(on: req.db)
        return cv.toResponseDTO(with: cv.user)
    }

    // MARK: Retrieve All
    func getAllHandler(_ req: Request) async throws -> [CV.ResponseDTO] {
        let cvs = try await CV.query(on: req.db).with(\.$user).all()
        return cvs.map { $0.toResponseDTO(with: $0.user) }
    }

    // MARK: Retrieve One
    func getHandler(_ req: Request) async throws -> CV.ResponseDTO {
        guard let cvId = req.parameters.get("cvId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid CV ID format")
        }
        guard let cv = try await CV.query(on: req.db)
                .filter(\.$id == cvId)
                .with(\.$user)
                .first() else {
            throw Abort(.notFound, reason: "CV not found")
        }
        return cv.toResponseDTO(with: cv.user)
    }

    // MARK: Update
    func updateHandler(_ req: Request) async throws -> CV.ResponseDTO {
        let user = try req.auth.require(User.self)
        guard let cvId = req.parameters.get("cvId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid CV ID format")
        }

        let updateDTO = try req.content.decode(CV.UpdateDTO.self)

        guard let cv = try await CV.find(cvId, on: req.db) else {
            throw Abort(.notFound, reason: "CV not found")
        }
        guard cv.$user.id == user.id else {
            throw Abort(.forbidden, reason: "You can only update your own CVs")
        }

        // Обновляем текстовые поля
        cv.update(from: updateDTO)

        // Если передан новый файл, сохраняем его и удаляем старый
        if let file = updateDTO.pdfFile {
            guard let ext = file.extension?.lowercased(), ext == "pdf" else {
                throw Abort(.badRequest, reason: "Only PDF files are allowed")
            }
            guard file.data.readableBytes <= 10 * 1024 * 1024 else {
                throw Abort(.badRequest, reason: "File too large (max 10 MB)")
            }

            let filename = "\(UUID().uuidString).pdf"
            let path = req.application.directory.publicDirectory + "uploads/cv/" + filename
            try await req.fileio.writeFile(file.data, at: path)

            // Удаляем старый файл, если он был
            if !cv.pdf.isEmpty {
                let oldPath = req.application.directory.publicDirectory + cv.pdf.replacingOccurrences(of: "/uploads/", with: "uploads/")
                try? FileManager.default.removeItem(atPath: oldPath)
            }

            cv.pdf = "/uploads/cv/\(filename)"
        }

        try await cv.update(on: req.db)
        try await cv.$user.load(on: req.db)
        return cv.toResponseDTO(with: cv.user)
    }

    // MARK: Delete
    func deleteHandler(_ req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        guard let cvId = req.parameters.get("cvId", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        guard let cv = try await CV.find(cvId, on: req.db) else {
            throw Abort(.notFound)
        }
        guard cv.$user.id == user.id else {
            throw Abort(.forbidden)
        }

        // Удаляем файл с диска
        if !cv.pdf.isEmpty {
            let filePath = req.application.directory.publicDirectory + cv.pdf.replacingOccurrences(of: "/uploads/", with: "uploads/")
            try? FileManager.default.removeItem(atPath: filePath)
        }

        try await cv.delete(on: req.db)
        return .noContent
    }

    // MARK: Get CVs by User
    func getCVsByUserHandler(_ req: Request) async throws -> [CV.ResponseDTO] {
        guard let userId = req.parameters.get("userId", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        let cvs = try await CV.query(on: req.db)
            .filter(\.$user.$id == userId)
            .with(\.$user)
            .all()
        return cvs.map { $0.toResponseDTO(with: $0.user) }
    }
}
