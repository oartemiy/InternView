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
    }
    
    func createHandler(_ req: Request) async throws -> Response {
        guard let cv = try? req.content.decode(CV.self) else {
            throw Abort(.badRequest, reason: "It is impossible to decode the CV model")
        }
        try await cv.save(on: req.db)
        return try await cv.encodeResponse(status: .created, for: req)
    }
}
