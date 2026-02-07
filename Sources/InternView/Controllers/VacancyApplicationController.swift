//
//  VacancyApplicationController.swift
//  InternView
//
//  Created by Артемий Образцов on 07.02.2026.
//

import Fluent
import Vapor

struct VacancyApplicationController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let applicationsGroup = routes.grouped("applications")
        
        // Все маршруты требуют авторизации
        let basicMW = User.authenticator()
        let guardMW = User.guardMiddleware()
        let protected = applicationsGroup.grouped(basicMW, guardMW)
        
        protected.post(use: createHandler)
        protected.get("my", use: getMyApplicationsHandler)
        protected.put(":applicationId", use: updateHandler)
        protected.delete(":applicationId", use: deleteHandler)
        protected.get("vacancy", ":vacancyId", use: getApplicationsForVacancyHandler)
    }
    
    // MARK: - CRUD
    
    // Создание отклика на вакансию (только для интернов)
    func createHandler(_ req: Request) async throws -> VacancyApplication.ResponseDTO {
        let user = try req.auth.require(User.self)
        
        guard user.role == "intern" else {
            throw Abort(.forbidden, reason: "Only interns can apply for vacancies")
        }
        
        let createDTO = try req.content.decode(VacancyApplication.CreateDTO.self)
        
        // Проверяем существование вакансии
        guard let vacancy = try await Vacancy.find(createDTO.vacancyId, on: req.db) else {
            throw Abort(.notFound, reason: "Vacancy not found")
        }
        
        // Проверяем, что вакансия активна
        guard vacancy.isActive else {
            throw Abort(.badRequest, reason: "Vacancy is not active")
        }
        
        // Проверяем, что пользователь еще не откликался на эту вакансию
        let existingApplication = try await VacancyApplication.query(on: req.db)
            .filter(\.$vacancy.$id == createDTO.vacancyId)
            .filter(\.$intern.$id == user.id!)
            .first()
        
        if existingApplication != nil {
            throw Abort(.conflict, reason: "You have already applied for this vacancy")
        }
        
        // Если указано CV, проверяем что оно принадлежит пользователю
        if let cvId = createDTO.cvId {
            guard let cv = try await CV.find(cvId, on: req.db) else {
                throw Abort(.notFound, reason: "CV not found")
            }
            
            guard cv.$user.id == user.id else {
                throw Abort(.forbidden, reason: "CV does not belong to you")
            }
        }
        
        let application = VacancyApplication(from: createDTO, internID: user.id!)
        try await application.save(on: req.db)
        
        // Загружаем связанные данные
        try await application.$vacancy.load(on: req.db)
        try await application.$intern.load(on: req.db)
        if let cvId = application.$cv.id {
            application.cv = try await CV.find(cvId, on: req.db)
        }
        
        return application.toResponseDTO(
            intern: application.intern,
            cv: application.cv
        )
    }
    
    // Получение всех откликов текущего пользователя (интерна)
    func getMyApplicationsHandler(_ req: Request) async throws -> [VacancyApplication.ResponseDTO] {
        let user = try req.auth.require(User.self)
        
        guard user.role == "intern" else {
            throw Abort(.forbidden, reason: "Only interns have applications")
        }
        
        let applications = try await VacancyApplication.query(on: req.db)
            .filter(\.$intern.$id == user.id!)
            .with(\.$vacancy)
            .with(\.$cv)
            .sort(\.$appliedAt, .descending)
            .all()
        
        return applications.map { application in
            application.toResponseDTO(cv: application.cv)
        }
    }
    
    // Обновление отклика (изменение статуса рекрутером или отмена интерном)
    func updateHandler(_ req: Request) async throws -> VacancyApplication.ResponseDTO {
        let user = try req.auth.require(User.self)
        
        guard let applicationId = req.parameters.get("applicationId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid Application ID format")
        }
        
        guard let application = try await VacancyApplication.query(on: req.db)
            .filter(\.$id == applicationId)
            .with(\.$vacancy)
            .first() else {
            throw Abort(.notFound, reason: "Application not found")
        }
        
        let updateDTO = try req.content.decode(VacancyApplication.UpdateDTO.self)
        
        // Проверяем права
        if user.role == "recruiter" {
            // Рекрутер может менять только статус отклика на свою вакансию
            guard application.vacancy.$recruiter.id == user.id else {
                throw Abort(.forbidden, reason: "You can only update applications for your own vacancies")
            }
            
            if let status = updateDTO.status {
                application.status = status
            }
        } else if user.role == "intern" {
            // Интерн может менять только свои отклики
            guard application.$intern.id == user.id else {
                throw Abort(.forbidden, reason: "You can only update your own applications")
            }
            
            // Интерн может обновлять сопроводительное письмо и ссылку на резюме
            if let coverLetter = updateDTO.coverLetter {
                application.coverLetter = coverLetter
            }
            
            if let resumeUrl = updateDTO.resumeUrl {
                application.resumeURL = resumeUrl
            }
            
            // Интерн может отменить отклик (статус cancelled)
            if let status = updateDTO.status, status == "cancelled" {
                application.status = status
            }
        }
        
        try await application.update(on: req.db)
        
        // Загружаем обновленные данные
        try await application.$intern.load(on: req.db)
        try await application.$cv.load(on: req.db)
        
        return application.toResponseDTO(
            intern: application.intern,
            cv: application.cv
        )
    }
    
    // Удаление отклика (только интерн, который создал, или рекрутер)
    func deleteHandler(_ req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        
        guard let applicationId = req.parameters.get("applicationId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid Application ID format")
        }
        
        guard let application = try await VacancyApplication.query(on: req.db)
            .filter(\.$id == applicationId)
            .with(\.$vacancy)
            .first() else {
            throw Abort(.notFound, reason: "Application not found")
        }
        
        // Проверяем права: интерн может удалить свой отклик, рекрутер - отклик на свою вакансию
        let canDelete = (user.role == "intern" && application.$intern.id == user.id) ||
        (user.role == "recruiter" && application.vacancy.$recruiter.id == user.id)
        
        guard canDelete else {
            throw Abort(.forbidden, reason: "You don't have permission to delete this application")
        }
        
        try await application.delete(on: req.db)
        return .noContent
    }
    
    // Получение всех откликов на конкретную вакансию (для рекрутера)
    func getApplicationsForVacancyHandler(_ req: Request) async throws -> [VacancyApplication.ResponseDTO] {
        let user = try req.auth.require(User.self)
        
        guard user.role == "recruiter" else {
            throw Abort(.forbidden, reason: "Only recruiters can view applications")
        }
        
        guard let vacancyId = req.parameters.get("vacancyId", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid Vacancy ID format")
        }
        
        // Проверяем, что вакансия принадлежит пользователю
        guard let vacancy = try await Vacancy.query(on: req.db)
            .filter(\.$id == vacancyId)
            .filter(\.$recruiter.$id == user.id!)
            .first() else {
            throw Abort(.notFound, reason: "Vacancy not found or you don't have permission")
        }
        
        let applications = try await VacancyApplication.query(on: req.db)
            .filter(\.$vacancy.$id == vacancy.id!)
            .with(\.$intern)
            .with(\.$cv)
            .sort(\.$appliedAt, .descending)
            .all()
        
        return applications.map { application in
            application.toResponseDTO(intern: application.intern, cv: application.cv)
        }
    }
}
