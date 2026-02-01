//
//  CVController.swift
//  InternView
//
//  Created by Артемий Образцов on 01.02.2026.
//

import Fluent
import Vapor

struct CVController: RouteCollection {
    func boot(routes: any Vapor.RoutesBuilder) throws {
        let cvGroup = routes.grouped("CVs")
        cvGroup.post(use: createHandler)
        cvGroup.get(use: getAllHandler)
        cvGroup.get(":cvID", use: getHandler)
    }
    
    func createHandler(_ req: Request) async throws -> CV {
        guard let cv = try? req.content.decode(CV.self) else {
            throw Abort(.badRequest, reason: "It is impossible to decode the CV model")
        }
        try await cv.save(on: req.db)
        return cv
    }
    
    func getAllHandler(_ req: Request) async throws -> [CV] {
        let cvs = try await CV.query(on: req.db).all()
        return cvs
    }
    
    func getHandler(_ req: Request) async throws -> CV {
        guard let cv = try await CV.find(req.parameters.get("cvID"), on: req.db) else {
            throw Abort(.notFound, reason: "CV with this ID does not exist")
        }
        return cv
    }
}
